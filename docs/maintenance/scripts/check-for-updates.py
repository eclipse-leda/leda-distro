#!/usr/bin/env python3
"""Check active Eclipse BitBake recipes and SDV container recipes for updates."""

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path


GITHUB_URI = re.compile(
    r"github\.com[:/]([^/\s;]+/[^/\s;]+)",
    re.IGNORECASE,
)
CONTAINER_RECIPE_DIRECTORY = "sdv-containers"
DEPRECATED_IMAGE_PREFIX = "ghcr.io/eclipse/"
ECLIPSE_PATH_MARKERS = (
    "eclipse-",
    "meta-kanto",
    "meta-velocitas",
    "meta-eclipse",
)
CONTAINER_BINARY_PACKAGES = {
    "sdv-container-cloudconnector": ("leda-contrib-cloud-connector",),
    "sdv-container-feedercan": (),
    "sdv-container-helloworld": (),
    "sdv-container-hvacservice": ("hvac-service-example",),
    "sdv-container-otelagent": (),
    "sdv-container-otelexporter": (),
    "sdv-container-seatservice": ("seat-service-example",),
    "sdv-container-selfupdateagent": ("leda-contrib-self-update-agent",),
    "sdv-container-vehicleupdatemanager": (
        "leda-contrib-vehicle-update-manager",
    ),
    "sdv-kuksa-val-databroker": ("databroker",),
}
NAMED_ECLIPSE_PROJECTS = {
    "Eclipse Velocitas": "eclipse-velocitas/",
}


def normalize_version(version):
    return str(version or "").strip().removeprefix("v")


def numeric_version(version):
    normalized = normalize_version(version)
    normalized = re.sub(r"\.AUTOINC(?:\+.*)?$", "", normalized, flags=re.IGNORECASE)
    normalized = re.sub(r"\+git.*$", "", normalized, flags=re.IGNORECASE)
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", normalized):
        return None
    parts = [int(part) for part in normalized.split(".")]
    while len(parts) > 1 and parts[-1] == 0:
        parts.pop()
    return tuple(parts)


def versions_match(first, second):
    first_numeric = numeric_version(first)
    second_numeric = numeric_version(second)
    if first_numeric is None or second_numeric is None:
        return None
    return first_numeric == second_numeric


def version_is_newer(candidate, current):
    candidate_numeric = numeric_version(candidate)
    current_numeric = numeric_version(current)
    if candidate_numeric is None or current_numeric is None:
        return None
    return candidate_numeric > current_numeric


def version_key(version):
    """Sort numeric version components numerically, with text as a tie-breaker."""
    return tuple(
        (1, int(part)) if part.isdigit() else (0, part.lower())
        for part in re.split(r"([0-9]+)", str(version))
        if part
    )


def repositories_from_uri(uri):
    repositories = set()
    for match in GITHUB_URI.finditer(uri or ""):
        repository = match.group(1).rstrip(".,)")
        if repository.endswith(".git"):
            repository = repository[:-4]
        repositories.add(repository)
    return repositories


def primary_eclipse_repository(uri, package_name):
    repositories = [
        match.group(1).rstrip(".,)").removesuffix(".git")
        for match in GITHUB_URI.finditer(uri or "")
        if is_eclipse_repository(match.group(1))
    ]
    if not repositories:
        return None

    normalized_package = re.sub(r"[^a-z0-9]", "", package_name.lower())
    for repository in repositories:
        project = repository.rpartition("/")[2]
        normalized_project = re.sub(r"[^a-z0-9]", "", project.lower())
        if normalized_package in normalized_project or normalized_project in normalized_package:
            return repository
    return repositories[0]


def is_eclipse_repository(repository):
    owner = repository.partition("/")[0].lower()
    return owner == "eclipse" or owner.startswith("eclipse-")


def extract_recipe_data(tinfoil, filepath):
    """Read the expanded metadata used to identify source and container recipes."""
    try:
        data = tinfoil.parse_recipe_file(os.path.abspath(filepath))
    except Exception as error:
        print(f"  [!] Failed to parse recipe {filepath}: {error}")
        return None

    return {
        "PN": data.getVar("PN"),
        "PV": data.getVar("PV"),
        "SRC_URI": data.getVar("SRC_URI") or "",
        "SDV_IMAGE_REF": data.getVar("SDV_IMAGE_REF"),
        "SDV_IMAGE_TAG": data.getVar("SDV_IMAGE_TAG"),
        "OCI_IMAGE_TAG": data.getVar("OCI_IMAGE_TAG"),
        "IMAGE_INSTALL": data.getVar("IMAGE_INSTALL") or "",
        "SUMMARY": data.getVar("SUMMARY") or "",
        "path": str(filepath),
    }


def is_active_path(path, layer_paths):
    recipe_path = Path(path).resolve()
    return any(
        recipe_path.is_relative_to(Path(layer_path).resolve())
        for layer_path in layer_paths
    )


def is_container_recipe(path):
    return CONTAINER_RECIPE_DIRECTORY in Path(path).parts


def is_eclipse_recipe_candidate(path, package_name):
    normalized_path = Path(path).as_posix().lower()
    return (
        is_container_recipe(path)
        or any(marker in normalized_path for marker in ECLIPSE_PATH_MARKERS)
        or "eclipse-" in package_name.lower()
    )


def inventory_recipes(tinfoil, recipe_cache, layer_paths):
    """Discover Eclipse source recipes and every active SDV container recipe."""
    source_recipes = []
    container_recipes = []
    seen_paths = set()

    for package_name, paths in recipe_cache.pkg_pn.items():
        for path in paths:
            if path in seen_paths or not is_active_path(path, layer_paths):
                continue
            seen_paths.add(path)

            container = is_container_recipe(path)
            if not container and not is_eclipse_recipe_candidate(path, package_name):
                continue

            data = extract_recipe_data(tinfoil, path)
            if data is None:
                continue

            if container:
                container_recipes.append(data)
                continue

            repository = primary_eclipse_repository(
                data["SRC_URI"], data["PN"] or package_name
            )
            if repository:
                source_recipes.append({**data, "repository": repository})

    return (
        select_latest_records(source_recipes, ("PN",)),
        select_latest_records(container_recipes, ("PN",)),
    )


def select_latest_records(records, group_fields):
    selected = {}
    for record in records:
        key = tuple(record[field] for field in group_fields)
        current = selected.get(key)
        if current is None or version_key(record["PV"] or "") > version_key(
            current["PV"] or ""
        ):
            selected[key] = record
    return sorted(
        selected.values(),
        key=lambda record: tuple(str(record[field]) for field in group_fields),
    )


def get_latest_github_release(github_client, repository):
    """Return the latest stable GitHub release version, or None on API failure."""
    try:
        release = github_client.get_repo(repository).get_latest_release()
    except Exception as error:
        print(f"  [!] Error fetching GitHub data for {repository}: {error}")
        return None
    return normalize_version(release.tag_name)


def repository_from_image_reference(reference, source_repositories):
    """Associate an image namespace with a known source repository when possible."""
    if not reference:
        return None

    parts = reference.split("/")
    if len(parts) < 3 or "." not in parts[0]:
        return None

    image_repository = "/".join(parts[1:3]).lower()
    exact = [
        repository
        for repository in source_repositories
        if repository.lower() == image_repository
    ]
    if exact:
        return sorted(exact)[0]

    project_name = parts[2].lower()
    same_project = [
        repository
        for repository in source_repositories
        if repository.rpartition("/")[2].lower() == project_name
    ]
    if len(same_project) == 1:
        return same_project[0]

    owner = parts[1].lower()
    if owner == "eclipse" or owner.startswith("eclipse-"):
        return "/".join(parts[1:3])
    return None


def image_reference(recipe_data):
    reference = recipe_data.get("SDV_IMAGE_REF")
    tag = recipe_data.get("SDV_IMAGE_TAG")
    if reference:
        return reference, tag or "latest"

    image_tag = recipe_data.get("OCI_IMAGE_TAG")
    if image_tag:
        if ":" in image_tag:
            return tuple(image_tag.rsplit(":", 1))
        return image_tag, "latest"

    return None


def is_deprecated_image_reference(reference):
    return bool(reference and reference.lower().startswith(DEPRECATED_IMAGE_PREFIX))


def manifest_image_reference(path):
    try:
        with path.open(encoding="utf-8") as manifest_file:
            manifest = json.load(manifest_file)
    except (OSError, json.JSONDecodeError) as error:
        print(f"  [!] Cannot read manifest {path}: {error}")
        return None

    if not isinstance(manifest, dict):
        print(f"  [!] Manifest has an invalid top-level value: {path}")
        return None
    image = manifest.get("image", {})
    if not isinstance(image, dict):
        print(f"  [!] Manifest image field is invalid: {path}")
        return None
    return image.get("name")


def find_manifests(layer_paths):
    manifests = []
    for layer_path in layer_paths:
        recipes_dir = Path(layer_path) / "recipes-sdv"
        if not recipes_dir.is_dir():
            continue
        for path in recipes_dir.rglob("*.json"):
            if "kanto-containers" not in path.parts:
                continue
            image = manifest_image_reference(path)
            if image:
                manifests.append((path, image))
    return manifests


def projects_without_recipes(source_recipes, container_recipes):
    absent = []
    for project, repository_prefix in NAMED_ECLIPSE_PROJECTS.items():
        source_found = any(
            recipe["repository"].lower().startswith(repository_prefix)
            for recipe in source_recipes
        )
        container_found = any(
            repository_prefix in (recipe.get("SDV_IMAGE_REF") or "").lower()
            or "velocitas" in recipe["PN"].lower()
            or "velocitas" in recipe["SUMMARY"].lower()
            for recipe in container_recipes
        )
        if not source_found and not container_found:
            absent.append(project)
    return absent


def image_without_tag(reference):
    if not reference:
        return ""
    last_slash = reference.rfind("/")
    last_colon = reference.rfind(":")
    if last_colon > last_slash:
        return reference[:last_colon]
    return reference


def check_manifests(container, image, manifests, pending_updates=None):
    if image is None:
        return
    expected_reference = f"{image[0]}:{image[1]}"
    matches = [
        (path, manifest_image)
        for path, manifest_image in manifests
        if image_without_tag(manifest_image) == image_without_tag(image[0])
    ]
    for path, manifest_image in matches:
        if is_deprecated_image_reference(manifest_image):
            print(
                f"  DEPRECATED IMAGE REGISTRY: {path} still uses "
                f"{DEPRECATED_IMAGE_PREFIX}; use the project-specific "
                "Eclipse registry namespace."
            )
        if manifest_image != expected_reference:
            print(
                f"  MANIFEST UPDATE REQUIRED: {path} image.name "
                f"{manifest_image} -> {expected_reference}"
            )
            if pending_updates is not None:
                pending_updates.append(
                    {
                        "kind": "manifest",
                        "path": path,
                        "old_image": manifest_image,
                        "new_image": expected_reference,
                        "description": (
                            f"Update manifest image tag in {path}: "
                            f"{manifest_image} -> {expected_reference}"
                        ),
                    }
                )
        else:
            print(f"  Manifest matches: {path}")


def source_versions_for_container(container, source_recipes, source_repositories):
    image = image_reference(container)
    linked = []
    package_name = container["PN"]

    if package_name in CONTAINER_BINARY_PACKAGES:
        package_names = set(CONTAINER_BINARY_PACKAGES[package_name])
        linked.extend(
            record for record in source_recipes if record["PN"] in package_names
        )
    elif image and container.get("SDV_IMAGE_REF"):
        repository = repository_from_image_reference(
            image[0], source_repositories
        )
        if repository:
            linked.extend(
                record
                for record in source_recipes
                if record["repository"] == repository
            )

    installed_packages = set(container.get("IMAGE_INSTALL", "").split())
    if installed_packages:
        linked.extend(
            record
            for record in source_recipes
            if record["PN"] in installed_packages
        )

    unique = {(record["PN"], record["repository"], record["path"]): record for record in linked}
    return list(unique.values())


def check_container(
    container,
    source_recipes,
    source_repositories,
    github_client,
    manifests,
    release_cache,
    pending_updates=None,
):
    package_name = container["PN"]
    image = image_reference(container)
    print(f"\nContainer recipe: {package_name} ({container['path']})")
    if image is None:
        print("  No image reference or image tag is configured.")
        return 0, 0

    image_name, image_tag = image
    print(f"  Image: {image_name}:{image_tag}")
    if is_deprecated_image_reference(image_name):
        print(
            f"  DEPRECATED IMAGE REGISTRY: {image_name} uses "
            f"{DEPRECATED_IMAGE_PREFIX}; use the project-specific "
            "Eclipse registry namespace."
        )
    source_matches = source_versions_for_container(
        container, source_recipes, source_repositories
    )
    linked_repositories = {record["repository"] for record in source_matches}
    github_repository = next(iter(sorted(linked_repositories)), None)
    if github_repository is None and container.get("SDV_IMAGE_REF"):
        github_repository = repository_from_image_reference(
            image_name, source_repositories
        )

    if container.get("SDV_IMAGE_REF"):
        if github_repository is None:
            print("  Upstream GitHub repository could not be inferred for this image.")
        else:
            if github_repository not in release_cache:
                release_cache[github_repository] = get_latest_github_release(
                    github_client, github_repository
                )
            latest_release = release_cache[github_repository]
            if latest_release is None:
                print(f"  GitHub release unavailable: {github_repository}")
            elif versions_match(image_tag, latest_release) is None:
                print(
                    f"  Cannot compare non-versioned container tag "
                    f"{image_tag!r} with GitHub releases."
                )
            elif not versions_match(image_tag, latest_release):
                print(
                    f"  CONTAINER UPDATE AVAILABLE: {image_tag} -> "
                    f"{latest_release} ({github_repository})"
                )
                if pending_updates is not None and version_is_newer(
                    latest_release, image_tag
                ):
                    pending_updates.append(
                        {
                            "kind": "container-recipe",
                            "path": Path(container["path"]),
                            "old_version": image_tag,
                            "new_version": latest_release,
                            "description": (
                                f"Create a new version of container recipe "
                                f"{container['path']} with image tag "
                                f"{latest_release}"
                            ),
                        }
                    )
            else:
                print(f"  Container tag matches latest release {latest_release}.")
        if github_repository is not None:
            latest_release = release_cache.get(github_repository)
        else:
            latest_release = None
    else:
        latest_release = None

    mismatches = 0
    unverifiable = 0
    for source in source_matches:
        source_version = normalize_version(source["PV"])
        if container.get("SDV_IMAGE_REF"):
            matches = versions_match(source_version, image_tag)
            if matches is None:
                print(
                    f"  HYBRID VERSION UNVERIFIABLE: binary {source['PN']} "
                    f"{source_version} vs container {image_tag}"
                )
                unverifiable += 1
            elif not matches:
                print(
                    f"  HYBRID VERSION MISMATCH: binary {source['PN']} "
                    f"{source_version} vs container {image_tag}"
                )
                mismatches += 1
            else:
                print(
                    f"  Hybrid version matches: binary {source['PN']} "
                    f"{source_version} and container {image_tag}."
                )
        else:
            print(
                f"  Container image includes binary {source['PN']} "
                f"version {source_version}."
            )

    manifest_image = image
    if container.get("SDV_IMAGE_REF") and latest_release:
        manifest_image = (image_name, latest_release)
    check_manifests(container, manifest_image, manifests, pending_updates)
    return mismatches, unverifiable


def versioned_recipe_path(recipe_path, version):
    if not re.fullmatch(r"[A-Za-z0-9.+_-]+", version):
        raise ValueError(f"version cannot be used in a recipe filename: {version!r}")
    if recipe_path.suffix != ".bb":
        raise ValueError(f"not a BitBake recipe: {recipe_path}")

    prefix, separator, _suffix = recipe_path.stem.rpartition("_")
    if not separator:
        prefix = recipe_path.stem
    return recipe_path.with_name(f"{prefix}_{version}.bb")


def versioned_recipe_contents(recipe_path, version, source_revision=None, image_tag=None):
    contents = recipe_path.read_text(encoding="utf-8")
    pv_pattern = re.compile(
        r"(?m)^(?P<prefix>[ \t]*PV[ \t]*=[ \t]*)(?P<quote>[\"'])"
        r"(?P<value>[^\"'\r\n]+)(?P=quote)(?P<suffix>[ \t]*(?:#.*)?$)"
    )
    pv_matches = list(pv_pattern.finditer(contents))
    if len(pv_matches) > 1:
        raise ValueError(f"multiple PV assignments in {recipe_path}")
    if pv_matches:
        old_pv = pv_matches[0].group("value")
        if "${" in old_pv:
            raise ValueError(f"cannot safely replace dynamic PV in {recipe_path}")
        contents = pv_pattern.sub(
            lambda match: (
                f"{match.group('prefix')}{match.group('quote')}{version}"
                f"{match.group('quote')}{match.group('suffix')}"
            ),
            contents,
            count=1,
        )

    if source_revision is not None:
        srcrev_pattern = re.compile(
            r"(?m)^(?P<prefix>[ \t]*SRCREV[ \t]*=[ \t]*)(?P<quote>[\"'])"
            r"(?P<value>[^\"'\r\n]+)(?P=quote)(?P<suffix>[ \t]*(?:#.*)?$)"
        )
        srcrev_matches = list(srcrev_pattern.finditer(contents))
        if len(srcrev_matches) != 1:
            raise ValueError(
                f"expected exactly one literal SRCREV assignment in {recipe_path}; "
                f"found {len(srcrev_matches)}"
            )
        contents = srcrev_pattern.sub(
            lambda match: (
                f"{match.group('prefix')}{match.group('quote')}{source_revision}"
                f"{match.group('quote')}{match.group('suffix')}"
            ),
            contents,
            count=1,
        )

    if image_tag is not None:
        tag_pattern = re.compile(
            r"(?m)^(?P<prefix>[ \t]*SDV_IMAGE_TAG[ \t]*=[ \t]*)(?P<quote>[\"'])"
            r"(?P<value>[^\"'\r\n]+)(?P=quote)(?P<suffix>[ \t]*(?:#.*)?$)"
        )
        tag_matches = list(tag_pattern.finditer(contents))
        if len(tag_matches) != 1:
            raise ValueError(
                f"expected exactly one literal SDV_IMAGE_TAG assignment in "
                f"{recipe_path}; found {len(tag_matches)}"
            )
        contents = tag_pattern.sub(
            lambda match: (
                f"{match.group('prefix')}{match.group('quote')}{image_tag}"
                f"{match.group('quote')}{match.group('suffix')}"
            ),
            contents,
            count=1,
        )

    return contents


def create_versioned_recipe(
    recipe_path, version, *, source_revision=None, image_tag=None
):
    destination = versioned_recipe_path(recipe_path, version)
    if destination.exists():
        raise FileExistsError(f"refusing to overwrite existing recipe {destination}")
    contents = versioned_recipe_contents(
        recipe_path, version, source_revision=source_revision, image_tag=image_tag
    )
    with destination.open("x", encoding="utf-8", newline="") as recipe_file:
        recipe_file.write(contents)
    shutil.copymode(recipe_path, destination)
    return destination


def update_manifest_image(path, old_image, new_image):
    contents = path.read_text(encoding="utf-8")
    try:
        manifest = json.loads(contents)
    except json.JSONDecodeError as error:
        raise ValueError(f"invalid JSON in {path}: {error}") from error
    if not isinstance(manifest, dict) or not isinstance(
        manifest.get("image"), dict
    ):
        raise ValueError(f"invalid image object in {path}")
    current_image = manifest["image"].get("name")
    if current_image != old_image:
        raise ValueError(
            f"manifest image changed since scan ({current_image!r} != "
            f"{old_image!r}); refusing to overwrite {path}"
        )

    image_name_pattern = re.compile(
        r'(?P<prefix>"image"\s*:\s*\{[^{}]*?"name"\s*:\s*)'
        + re.escape(json.dumps(old_image, ensure_ascii=False))
    )
    updated_contents, replacements = image_name_pattern.subn(
        lambda match: match.group("prefix")
        + json.dumps(new_image, ensure_ascii=False),
        contents,
        count=1,
    )
    if replacements != 1:
        raise ValueError(f"could not locate image.name in {path}")
    path.write_text(updated_contents, encoding="utf-8")


def apply_update(update, github_client, commit_cache):
    kind = update["kind"]
    if kind == "manifest":
        update_manifest_image(
            update["path"], update["old_image"], update["new_image"]
        )
        print(f"  Updated manifest: {update['path']}")
        return

    if kind == "source-recipe":
        repository = update["repository"]
        version = update["new_version"]
        commit_key = (repository, version)
        if commit_key not in commit_cache:
            errors = []
            for release_tag in (version, f"v{version}"):
                try:
                    repo = github_client.get_repo(repository)
                    commit_cache[commit_key] = repo.get_commit(release_tag).sha
                    break
                except Exception as error:
                    errors.append(error)
            else:
                raise RuntimeError(
                    f"cannot resolve GitHub release {version} to a commit for "
                    f"{repository}: {errors[-1]}"
                ) from errors[-1]
        destination = create_versioned_recipe(
            update["path"],
            version,
            source_revision=commit_cache[commit_key],
        )
        print(f"  Created recipe: {destination}")
        return

    if kind == "container-recipe":
        destination = create_versioned_recipe(
            update["path"],
            update["new_version"],
            image_tag=update["new_version"],
        )
        print(f"  Created container recipe: {destination}")
        return

    raise ValueError(f"unknown update type: {kind}")


def process_pending_updates(
    updates,
    *,
    interactive=False,
    autoapply=False,
    github_client=None,
    input_fn=input,
):
    if not updates:
        print("\nNo applicable updates.")
        return

    if not interactive and not autoapply:
        print(f"\n{len(updates)} applicable update(s); use --apply to choose or --autoapply.")
        for update in updates:
            print(f"  Would apply: {update['description']}")
        return

    commit_cache = {}
    for update in updates:
        if update["kind"] in {"source-recipe", "container-recipe"}:
            try:
                destination = versioned_recipe_path(
                    update["path"], update["new_version"]
                )
            except ValueError as error:
                print(f"  [!] Cannot create recipe update: {error}", file=sys.stderr)
                continue
            if destination.exists():
                print(f"  Skipped; recipe already exists: {destination}")
                continue

        if interactive:
            try:
                response = input_fn(f"{update['description']}? [y/N] ")
            except EOFError:
                response = ""
            if response != "y":
                print("  Skipped.")
                continue
        try:
            apply_update(update, github_client, commit_cache)
        except (OSError, ValueError, RuntimeError) as error:
            print(f"  [!] Could not apply update: {error}", file=sys.stderr)


def parse_arguments():
    parser = argparse.ArgumentParser(
        description=(
            "Check Eclipse source recipes, SDV container recipes, and Kanto "
            "manifests in the active BitBake layers."
        )
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show discovered recipe and manifest counts",
    )
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--apply",
        action="store_true",
        help="prompt before applying each available update",
    )
    action.add_argument(
        "--autoapply",
        action="store_true",
        help="apply all available updates without prompting",
    )
    return parser.parse_args()


def main():
    args = parse_arguments()
    try:
        from github import Github
    except ImportError:
        print(
            "Error: PyGithub is required. Install it with 'pip install PyGithub'.",
            file=sys.stderr,
        )
        return 1

    try:
        from bb.tinfoil import Tinfoil
    except ImportError:
        print(
            "Error: BitBake Python modules not found. Run this script from a "
            "BitBake build environment (for example, after sourcing "
            "'oe-init-build-env').",
            file=sys.stderr,
        )
        return 1

    github_token = os.environ.get("GITHUB_TOKEN")
    github_client = Github(github_token) if github_token else Github()
    if not github_token:
        print("Note: GITHUB_TOKEN is unset; using unauthenticated GitHub limits.")

    print("--- Leda Distro Update Checker ---")
    with Tinfoil() as tinfoil:
        print("Initializing BitBake environment...")
        tinfoil.prepare(config_only=False)
        layer_paths = (tinfoil.config_data.getVar("BBLAYERS") or "").split()
        recipe_cache = tinfoil.cooker.recipecaches[""]
        source_recipes, container_recipes = inventory_recipes(
            tinfoil, recipe_cache, layer_paths
        )
        source_repositories = {
            recipe["repository"] for recipe in source_recipes
        }
        manifests = find_manifests(layer_paths)
        if args.verbose:
            print(
                f"Discovered {len(source_recipes)} Eclipse source recipe(s), "
                f"{len(container_recipes)} SDV container recipe(s), and "
                f"{len(manifests)} Kanto manifest(s)."
            )
        for project in projects_without_recipes(source_recipes, container_recipes):
            print(
                f"NOTE: {project} has no recipe or container in the active "
                "BitBake layers and cannot be version-checked."
            )

        release_cache = {}
        pending_updates = []
        source_updates = 0
        print("\nEclipse binary/source recipes:")
        for recipe in source_recipes:
            repository = recipe["repository"]
            if repository not in release_cache:
                release_cache[repository] = get_latest_github_release(
                    github_client, repository
                )
            latest_release = release_cache[repository]
            current_version = normalize_version(recipe["PV"])
            print(
                f"  {recipe['PN']} {current_version} "
                f"({repository}; {recipe['path']})"
            )
            if latest_release is None:
                print("    GitHub release unavailable; cannot compare.")
            elif numeric_version(current_version) is None:
                print(
                    f"    Cannot compare GitHub release to non-versioned "
                    f"BitBake PV {current_version!r}."
                )
            elif version_is_newer(latest_release, current_version):
                print(
                    f"    UPDATE AVAILABLE: {current_version} -> "
                    f"{latest_release}"
                )
                source_updates += 1
                pending_updates.append(
                    {
                        "kind": "source-recipe",
                        "path": Path(recipe["path"]),
                        "repository": repository,
                        "new_version": latest_release,
                        "description": (
                            f"Create a new version of recipe {recipe['path']} "
                            f"at {latest_release}"
                        ),
                    }
                )
            elif versions_match(current_version, latest_release):
                print("    Up to date.")
            elif version_is_newer(current_version, latest_release):
                print("    Current recipe is newer than the latest GitHub release.")
            else:
                print(
                    f"    Cannot compare BitBake version {current_version!r} "
                    f"with GitHub release {latest_release!r}."
                )

        hybrid_mismatches = 0
        hybrid_unverifiable = 0
        print("\nSDV container recipes:")
        for container in container_recipes:
            mismatches, unverifiable = check_container(
                container,
                source_recipes,
                source_repositories,
                github_client,
                manifests,
                release_cache,
                pending_updates,
            )
            hybrid_mismatches += mismatches
            hybrid_unverifiable += unverifiable

        print("\nSummary:")
        print(f"  Eclipse source recipes checked: {len(source_recipes)}")
        print(f"  Source updates available: {source_updates}")
        print(f"  SDV container recipes checked: {len(container_recipes)}")
        print(f"  Hybrid version mismatches: {hybrid_mismatches}")
        print(f"  Hybrid versions needing review: {hybrid_unverifiable}")
        print(f"  Kanto manifests checked: {len(manifests)}")
        process_pending_updates(
            pending_updates,
            interactive=args.apply,
            autoapply=args.autoapply,
            github_client=github_client,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
