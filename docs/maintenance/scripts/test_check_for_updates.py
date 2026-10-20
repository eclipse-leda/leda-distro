import importlib.util
import json
import sys
from pathlib import Path

import pytest


SCRIPT = Path(__file__).with_name("check-for-updates.py")
SPEC = importlib.util.spec_from_file_location("check_for_updates", SCRIPT)
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class FakeRecipeData:
    def __init__(self, values):
        self.values = values

    def getVar(self, name):
        return self.values.get(name)


class FakeTinfoil:
    def __init__(self, recipes):
        self.recipes = recipes

    def parse_recipe_file(self, path):
        return FakeRecipeData(self.recipes[path])


class FakeRecipeCache:
    def __init__(self, recipes_by_pn):
        self.pkg_pn = recipes_by_pn


def recipe(pn, pv, src_uri="", **values):
    result = {
        "PN": pn,
        "PV": pv,
        "SRC_URI": src_uri,
        "SDV_IMAGE_REF": None,
        "SDV_IMAGE_TAG": None,
        "OCI_IMAGE_TAG": None,
        "IMAGE_INSTALL": "",
        "SUMMARY": "",
    }
    result.update(values)
    return result


@pytest.mark.parametrize(
    ("uri", "expected"),
    [
        (
            "gitsm://github.com/eclipse-kuksa/kuksa-databroker.git;protocol=https",
            {"eclipse-kuksa/kuksa-databroker"},
        ),
        (
            "git://github.com/eclipse-kanto/container-management;"
            "git://github.com/eclipse-leda/leda-utils",
            {"eclipse-kanto/container-management", "eclipse-leda/leda-utils"},
        ),
        ("https://example.com/project.tar.gz", set()),
    ],
)
def test_repositories_from_uri(uri, expected):
    assert checker.repositories_from_uri(uri) == expected


def test_primary_eclipse_repository_prefers_repository_matching_recipe_name():
    uri = (
        "git://github.com/GNOME/glib.git;"
        "git://github.com/eclipse-leda/leda-contrib-self-update-agent.git;"
        "git://github.com/eclipse/paho.mqtt.c.git"
    )

    assert checker.primary_eclipse_repository(
        uri, "leda-contrib-self-update-agent"
    ) == "eclipse-leda/leda-contrib-self-update-agent"


def test_version_key_sorts_versions_numerically():
    assert sorted(["0.9.0", "0.17.0", "0.7.1"], key=checker.version_key) == [
        "0.7.1",
        "0.9.0",
        "0.17.0",
    ]


@pytest.mark.parametrize(
    ("first", "second", "expected"),
    [
        ("0.7.1", "v0.7.1", True),
        ("0.7.1+git", "0.7.1", True),
        ("0.7.1.AUTOINC+abc123", "v0.7.1", True),
        ("0.7.1", "0.7.2", False),
        ("git", "0.7.1", None),
    ],
)
def test_versions_match(first, second, expected):
    assert checker.versions_match(first, second) is expected


def test_get_latest_github_release_normalizes_tag():
    class Release:
        tag_name = "v1.2.3"

    class Repository:
        def get_latest_release(self):
            return Release()

    class GitHub:
        def get_repo(self, name):
            assert name == "eclipse-kuksa/kuksa-databroker"
            return Repository()

    assert checker.get_latest_github_release(
        GitHub(), "eclipse-kuksa/kuksa-databroker"
    ) == "1.2.3"


def test_get_latest_github_release_reports_errors(capsys):
    class GitHub:
        def get_repo(self, _name):
            raise RuntimeError("network unavailable")

    assert checker.get_latest_github_release(GitHub(), "owner/repository") is None
    assert "network unavailable" in capsys.readouterr().out


def test_inventory_discovers_kanto_velocitas_and_all_container_recipes(tmp_path):
    leda_layer = tmp_path / "meta-leda-components"
    kanto_path = str(
        tmp_path
        / "meta-kanto/recipes-containers/container-management/container-management_git.bb"
    )
    velocitas_path = str(
        leda_layer
        / "recipes-sdv/eclipse-velocitas/vehicle-app/vehicle-app_1.2.0.bb"
    )
    databroker_path = str(
        leda_layer / "recipes-sdv/eclipse-kuksa/databroker_0.7.1.bb"
    )
    container_path = str(
        leda_layer / "recipes-sdv/sdv-containers/sdv-container-vehicle-app_1.2.bb"
    )
    container_only_path = str(
        leda_layer / "recipes-sdv/sdv-containers/sdv-container-kanto_0.4.bb"
    )
    recipes = {
        kanto_path: recipe(
            "container-management",
            "0.12.0",
            "git://github.com/eclipse-kanto/container-management.git",
        ),
        velocitas_path: recipe(
            "vehicle-app",
            "1.2.0",
            "git://github.com/eclipse-velocitas/vehicle-app.git",
        ),
        databroker_path: recipe(
            "databroker",
            "0.7.1",
            "git://github.com/eclipse-kuksa/kuksa-databroker.git",
        ),
        container_path: recipe(
            "sdv-container-vehicle-app",
            "1.2",
            SDV_IMAGE_REF="ghcr.io/eclipse-velocitas/vehicle-app",
            SDV_IMAGE_TAG="1.2.0",
        ),
        container_only_path: recipe(
            "sdv-container-kanto",
            "0.4",
            SDV_IMAGE_REF="ghcr.io/eclipse-kanto/container-management",
            SDV_IMAGE_TAG="0.12.0",
        ),
    }
    cache = FakeRecipeCache(
        {
            "container-management": [kanto_path],
            "vehicle-app": [velocitas_path],
            "databroker": [databroker_path],
            "sdv-container-vehicle-app": [container_path],
            "sdv-container-kanto": [container_only_path],
        }
    )

    sources, containers = checker.inventory_recipes(
        FakeTinfoil(recipes), cache, [str(tmp_path)]
    )

    assert {(item["PN"], item["repository"]) for item in sources} == {
        ("container-management", "eclipse-kanto/container-management"),
        ("vehicle-app", "eclipse-velocitas/vehicle-app"),
        ("databroker", "eclipse-kuksa/kuksa-databroker"),
    }
    assert {item["PN"] for item in containers} == {
        "sdv-container-vehicle-app",
        "sdv-container-kanto",
    }


def test_inventory_selects_latest_recipe_per_package(tmp_path):
    layer = tmp_path / "meta-eclipse"
    older = str(layer / "recipes-sdv/eclipse-kuksa/databroker_0.9.0.bb")
    newer = str(layer / "recipes-sdv/eclipse-kuksa/databroker_0.17.0.bb")
    recipes = {
        older: recipe(
            "databroker", "0.9.0", "git://github.com/eclipse-kuksa/databroker.git"
        ),
        newer: recipe(
            "databroker", "0.17.0", "git://github.com/eclipse-kuksa/databroker.git"
        ),
    }

    sources, _ = checker.inventory_recipes(
        FakeTinfoil(recipes),
        FakeRecipeCache({"databroker": [older, newer]}),
        [str(layer)],
    )

    assert len(sources) == 1
    assert sources[0]["PV"] == "0.17.0"


def test_reports_named_projects_missing_from_active_layers():
    assert checker.projects_without_recipes([], []) == ["Eclipse Velocitas"]
    assert (
        checker.projects_without_recipes(
            [{"repository": "eclipse-velocitas/vehicle-app"}], []
        )
        == []
    )


@pytest.mark.parametrize(
    ("reference", "repositories", "expected"),
    [
        (
            "ghcr.io/eclipse-kuksa/kuksa-databroker",
            {"eclipse-kuksa/kuksa-databroker"},
            "eclipse-kuksa/kuksa-databroker",
        ),
        (
            "ghcr.io/boschglobal/kuksa.val.services/seat_service",
            {"eclipse/kuksa.val.services"},
            "eclipse/kuksa.val.services",
        ),
        ("hello-world", set(), None),
    ],
)
def test_repository_from_image_reference(reference, repositories, expected):
    assert checker.repository_from_image_reference(reference, repositories) == expected


def test_explicit_container_mapping_avoids_linking_unrelated_binary_from_same_repo():
    source_recipes = [
        {
            "PN": "databroker",
            "PV": "0.7.1",
            "repository": "eclipse-kuksa/kuksa-databroker",
            "path": "databroker_0.7.1.bb",
        },
        {
            "PN": "databroker-cli",
            "PV": "0.6.1",
            "repository": "eclipse-kuksa/kuksa-databroker",
            "path": "databroker-cli_0.6.1.bb",
        },
    ]
    container = recipe(
        "sdv-kuksa-val-databroker",
        "0.7.1",
        SDV_IMAGE_REF="ghcr.io/eclipse-kuksa/kuksa-databroker",
        SDV_IMAGE_TAG="0.7.1",
    )

    linked = checker.source_versions_for_container(
        container,
        source_recipes,
        {"eclipse-kuksa/kuksa-databroker"},
    )

    assert [record["PN"] for record in linked] == ["databroker"]


def test_image_reference_reads_registry_tag_and_local_oci_tag():
    assert checker.image_reference(
        {
            "SDV_IMAGE_REF": "ghcr.io/eclipse-kuksa/kuksa-databroker",
            "SDV_IMAGE_TAG": "0.7.1",
        }
    ) == ("ghcr.io/eclipse-kuksa/kuksa-databroker", "0.7.1")
    assert checker.image_reference({"OCI_IMAGE_TAG": "databroker:latest"}) == (
        "databroker",
        "latest",
    )
    assert checker.image_without_tag("ghcr.io:443/example/image:0.7.1") == (
        "ghcr.io:443/example/image"
    )


@pytest.mark.parametrize(
    ("reference", "expected"),
    [
        ("ghcr.io/eclipse/kuksa.val/databroker:0.3.0", True),
        ("GHCR.IO/ECLIPSE/kuksa.val/databroker:0.3.0", True),
        ("ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.1", False),
        ("ghcr.io/eclipse-kanto/container-management:0.12.0", False),
        ("ghcr.io/other-org/component:1.0.0", False),
    ],
)
def test_deprecated_registry_only_matches_legacy_eclipse_namespace(
    reference, expected
):
    assert checker.is_deprecated_image_reference(reference) is expected


def test_manifest_image_reference_reads_kanto_image_name(tmp_path):
    manifest = tmp_path / "databroker.json"
    manifest.write_text(
        json.dumps({"image": {"name": "ghcr.io/eclipse-kuksa/databroker:0.7.1"}})
    )

    assert checker.manifest_image_reference(manifest) == (
        "ghcr.io/eclipse-kuksa/databroker:0.7.1"
    )


def test_manifest_image_reference_reports_invalid_json_shape(tmp_path, capsys):
    manifest = tmp_path / "invalid.json"
    manifest.write_text("[]")

    assert checker.manifest_image_reference(manifest) is None
    assert "invalid top-level value" in capsys.readouterr().out


def test_find_manifests_scans_active_kanto_manifest_directory(tmp_path):
    layer = tmp_path / "meta-leda-components"
    manifest = (
        layer
        / "recipes-sdv/eclipse-leda/kanto-containers/core/databroker.json"
    )
    manifest.parent.mkdir(parents=True)
    manifest.write_text(
        json.dumps({"image": {"name": "ghcr.io/eclipse-kuksa/databroker:0.7.1"}})
    )

    assert checker.find_manifests([str(layer)]) == [
        (manifest, "ghcr.io/eclipse-kuksa/databroker:0.7.1")
    ]


def test_check_container_reports_release_hybrid_and_manifest_mismatches(
    tmp_path, capsys
):
    layer = tmp_path / "meta-leda-components"
    manifest = (
        layer
        / "recipes-sdv/eclipse-leda/kanto-containers/core/databroker.json"
    )
    manifest.parent.mkdir(parents=True)
    manifest.write_text(
        json.dumps(
            {
                "image": {
                    "name": "ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.0"
                }
            }
        )
    )
    source = {
        "PN": "databroker",
        "PV": "0.7.1",
        "repository": "eclipse-kuksa/kuksa-databroker",
        "path": "databroker_0.7.1.bb",
    }
    container = recipe(
        "sdv-kuksa-val-databroker",
        "0.7.0",
        SDV_IMAGE_REF="ghcr.io/eclipse-kuksa/kuksa-databroker",
        SDV_IMAGE_TAG="0.7.0",
    )
    container["path"] = "sdv-kuksa-val-databroker_0.7.0.bb"

    class Release:
        tag_name = "v0.7.1"

    class Repository:
        def get_latest_release(self):
            return Release()

    class GitHub:
        def get_repo(self, name):
            assert name == "eclipse-kuksa/kuksa-databroker"
            return Repository()

    mismatch_count = checker.check_container(
        container,
        [source],
        {source["repository"]},
        GitHub(),
        [(manifest, "ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.0")],
        {},
    )

    output = capsys.readouterr().out
    assert mismatch_count == (1, 0)
    assert "CONTAINER UPDATE AVAILABLE: 0.7.0 -> 0.7.1" in output
    assert "HYBRID VERSION MISMATCH: binary databroker 0.7.1 vs container 0.7.0" in output
    assert "MANIFEST UPDATE REQUIRED" in output
    assert "image.name ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.0" in output


def test_check_container_queues_new_versioned_container_recipe(capsys):
    container = recipe(
        "sdv-kuksa-val-databroker",
        "0.7.0",
        SDV_IMAGE_REF="ghcr.io/eclipse-kuksa/kuksa-databroker",
        SDV_IMAGE_TAG="0.7.0",
    )
    container["path"] = "sdv-kuksa-val-databroker_0.7.0.bb"

    class Release:
        tag_name = "v0.7.1"

    class Repository:
        def get_latest_release(self):
            return Release()

    class GitHub:
        def get_repo(self, _name):
            return Repository()

    updates = []
    checker.check_container(
        container,
        [],
        {"eclipse-kuksa/kuksa-databroker"},
        GitHub(),
        [],
        {},
        updates,
    )

    assert len(updates) == 1
    assert updates[0]["kind"] == "container-recipe"
    assert updates[0]["new_version"] == "0.7.1"


def test_check_container_marks_legacy_registry_deprecated(capsys):
    container = recipe(
        "sdv-kuksa-val-databroker",
        "0.3",
        SDV_IMAGE_REF="ghcr.io/eclipse/kuksa.val/databroker",
        SDV_IMAGE_TAG="0.3.0",
    )
    container["path"] = "sdv-kuksa-val-databroker_0.3.bb"
    manifest = Path("databroker.json")
    source = {
        "PN": "databroker",
        "PV": "0.3.0",
        "repository": "eclipse/kuksa.val",
        "path": "databroker_0.3.0.bb",
    }

    checker.check_container(
        container,
        [source],
        {source["repository"]},
        None,
        [(manifest, "ghcr.io/eclipse/kuksa.val/databroker:0.3.0")],
        {},
    )

    output = capsys.readouterr().out
    assert "DEPRECATED IMAGE REGISTRY" in output
    assert "ghcr.io/eclipse/" in output


def test_local_container_checks_included_binary_recipe_version(capsys):
    source = {
        "PN": "databroker",
        "PV": "0.7.1",
        "repository": "eclipse-kuksa/kuksa-databroker",
        "path": "databroker_0.7.1.bb",
    }
    container = recipe(
        "databroker-container",
        "git",
        OCI_IMAGE_TAG="databroker:latest",
        IMAGE_INSTALL="busybox databroker",
    )
    container["path"] = "databroker-container_git.bb"

    checker.check_container(
        container, [source], {source["repository"]}, None, [], {}
    )

    assert "Container image includes binary databroker version 0.7.1." in (
        capsys.readouterr().out
    )


def test_versioned_recipe_path_replaces_existing_version_suffix(tmp_path):
    recipe_path = tmp_path / "databroker_0.7.1.bb"

    assert checker.versioned_recipe_path(recipe_path, "0.8.0") == (
        tmp_path / "databroker_0.8.0.bb"
    )


def test_create_versioned_recipe_updates_pv_and_source_revision(tmp_path):
    original = tmp_path / "sample_1.0.bb"
    original.write_text(
        'PV = "1.0"\n'
        'SRC_URI = "git://github.com/eclipse/project.git"\n'
        'SRCREV = "oldrevision"\n'
    )

    created = checker.create_versioned_recipe(
        original, "1.1", source_revision="newrevision"
    )

    assert created == tmp_path / "sample_1.1.bb"
    assert created.read_text() == (
        'PV = "1.1"\n'
        'SRC_URI = "git://github.com/eclipse/project.git"\n'
        'SRCREV = "newrevision"\n'
    )
    assert original.read_text().endswith('SRCREV = "oldrevision"\n')


def test_create_versioned_container_recipe_updates_tag(tmp_path):
    original = tmp_path / "sdv-container_0.1.bb"
    original.write_text(
        'SUMMARY = "container"\n'
        'SDV_IMAGE_TAG = "1.0"\n'
    )

    created = checker.create_versioned_recipe(
        original, "1.1", image_tag="1.1"
    )

    assert created.name == "sdv-container_1.1.bb"
    assert 'SDV_IMAGE_TAG = "1.1"' in created.read_text()
    assert 'SDV_IMAGE_TAG = "1.0"' in original.read_text()


def test_create_versioned_recipe_rejects_existing_file_and_ambiguous_srcrev(
    tmp_path,
):
    original = tmp_path / "sample_1.0.bb"
    original.write_text('SRCREV = "one"\nSRCREV = "two"\n')
    destination = tmp_path / "sample_1.1.bb"
    destination.write_text("existing")

    with pytest.raises(FileExistsError):
        checker.create_versioned_recipe(
            original, "1.1", source_revision="new"
        )

    destination.unlink()
    with pytest.raises(ValueError, match="exactly one literal SRCREV"):
        checker.create_versioned_recipe(
            original, "1.1", source_revision="new"
        )


def test_update_manifest_image_changes_only_image_name_and_preserves_formatting(
    tmp_path,
):
    manifest = tmp_path / "databroker.json"
    manifest.write_text(
        '{\n    "image": {\n        "name": "ghcr.io/example/app:1.0"\n'
        "    },\n    \"label\": \"ghcr.io/example/app:1.0\"\n}\n"
    )

    checker.update_manifest_image(
        manifest,
        "ghcr.io/example/app:1.0",
        "ghcr.io/example/app:1.1",
    )

    result = manifest.read_text()
    assert '"name": "ghcr.io/example/app:1.1"' in result
    assert '"label": "ghcr.io/example/app:1.0"' in result
    assert result.startswith("{\n    ")


def test_update_manifest_image_refuses_stale_file(tmp_path):
    manifest = tmp_path / "databroker.json"
    manifest.write_text(
        json.dumps({"image": {"name": "ghcr.io/example/app:1.1"}})
    )

    with pytest.raises(ValueError, match="changed since scan"):
        checker.update_manifest_image(
            manifest,
            "ghcr.io/example/app:1.0",
            "ghcr.io/example/app:1.2",
        )


def test_process_pending_updates_prompts_each_update_and_accepts_only_y(
    tmp_path, capsys
):
    recipe_path = tmp_path / "container_1.0.bb"
    recipe_path.write_text('SDV_IMAGE_TAG = "1.0"\n')
    updates = [
        {
            "kind": "container-recipe",
            "path": recipe_path,
            "new_version": "1.1",
            "description": "Create container 1.1",
        },
        {
            "kind": "container-recipe",
            "path": recipe_path,
            "new_version": "1.2",
            "description": "Create container 1.2",
        },
        {
            "kind": "container-recipe",
            "path": recipe_path,
            "new_version": "1.3",
            "description": "Create container 1.3",
        },
    ]
    answers = iter(["y", "Y", "yes"])

    checker.process_pending_updates(
        updates,
        interactive=True,
        input_fn=lambda _prompt: next(answers),
    )

    assert (tmp_path / "container_1.1.bb").exists()
    assert not (tmp_path / "container_1.2.bb").exists()
    assert not (tmp_path / "container_1.3.bb").exists()
    assert capsys.readouterr().out.count("Skipped.") == 2


def test_process_pending_updates_autoapplies_without_prompt(tmp_path, monkeypatch):
    recipe_path = tmp_path / "container_1.0.bb"
    recipe_path.write_text('SDV_IMAGE_TAG = "1.0"\n')
    update = {
        "kind": "container-recipe",
        "path": recipe_path,
        "new_version": "1.1",
        "description": "Create container 1.1",
    }

    def unexpected_prompt(_prompt):
        pytest.fail("autoapply must not prompt")

    checker.process_pending_updates(
        [update],
        autoapply=True,
        input_fn=unexpected_prompt,
    )

    assert (tmp_path / "container_1.1.bb").exists()


def test_autoapply_creates_source_recipe_at_release_commit(tmp_path):
    original = tmp_path / "databroker_0.7.1.bb"
    original.write_text(
        'PV = "0.7.1"\n'
        'SRCREV = "oldrevision"\n'
    )
    requested_tags = []

    class Commit:
        sha = "newrevision"

    class Repository:
        def get_commit(self, tag):
            requested_tags.append(tag)
            if tag == "0.8.0":
                raise RuntimeError("release tag uses v prefix")
            return Commit()

    class GitHub:
        def get_repo(self, repository):
            assert repository == "eclipse-kuksa/kuksa-databroker"
            return Repository()

    checker.process_pending_updates(
        [
            {
                "kind": "source-recipe",
                "path": original,
                "repository": "eclipse-kuksa/kuksa-databroker",
                "new_version": "0.8.0",
                "description": "Create databroker 0.8.0",
            }
        ],
        autoapply=True,
        github_client=GitHub(),
    )

    created = tmp_path / "databroker_0.8.0.bb"
    assert created.read_text() == 'PV = "0.8.0"\nSRCREV = "newrevision"\n'
    assert original.read_text() == 'PV = "0.7.1"\nSRCREV = "oldrevision"\n'
    assert requested_tags == ["0.8.0", "v0.8.0"]


def test_apply_manifest_update_preserves_original_manifest_format(tmp_path):
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        '{\n  "image": {\n    "name": "ghcr.io/example/app:1.0"\n  }\n}\n'
    )
    checker.apply_update(
        {
            "kind": "manifest",
            "path": manifest,
            "old_image": "ghcr.io/example/app:1.0",
            "new_image": "ghcr.io/example/app:1.1",
            "description": "Update manifest",
        },
        github_client=None,
        commit_cache={},
    )

    assert manifest.read_text() == (
        '{\n  "image": {\n    "name": "ghcr.io/example/app:1.1"\n  }\n}\n'
    )


@pytest.mark.parametrize(
    ("arguments", "apply", "autoapply"),
    [
        (["checker"], False, False),
        (["checker", "--apply"], True, False),
        (["checker", "--autoapply"], False, True),
    ],
)
def test_cli_apply_options(arguments, apply, autoapply, monkeypatch):
    monkeypatch.setattr(sys, "argv", arguments)

    parsed = checker.parse_arguments()

    assert parsed.apply is apply
    assert parsed.autoapply is autoapply
