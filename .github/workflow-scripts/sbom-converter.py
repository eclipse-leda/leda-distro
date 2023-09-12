#!/usr/bin/env python3

# /********************************************************************************
# * Copyright (c) 2023 Contributors to the Eclipse Foundation
# *
# * See the NOTICE file(s) distributed with this work for additional
# * information regarding copyright ownership.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Apache License 2.0 which is available at
# * https://www.apache.org/licenses/LICENSE-2.0
# *
# * SPDX-License-Identifier: Apache-2.0
# ********************************************************************************/

import os
import sys
import shutil
import logging
import argparse
import subprocess
from pathlib import Path
from multiprocessing.pool import ThreadPool as Pool

logger = logging.getLogger("SBOM-CONVERTER")
logger.setLevel(os.getenv("CONVERTER_LOG_LEVEL", "INFO"))
logging.basicConfig(level=logging.INFO, format="[%(name)s %(levelname)s]: %(message)s")


def cyclonedx_cli_valid(cyclonedx_cli: Path) -> bool:
    try:
        s = subprocess.run(
            [cyclonedx_cli], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False
        )
        stdout = s.stdout.decode("ascii")
        return "cyclonedx" in stdout
    except Exception as ex:
        logger.error(f"Cyclonedx cyclonedx_cli in {cyclonedx_cli} not valid:\n{ex}")
        return False


def get_cyclonedx_cli() -> Path:
    """
    Tries to find the CYCLONEDX_CLI, throws if it fails
    """
    cyclonedx_cli = os.getenv("CYCLONEDX_CLI")
    if cyclonedx_cli is None:
        # If variable is not set, try PATH
        cyclonedx_cli = shutil.which("cyclonedx")
    cyclonedx_cli = Path(cyclonedx_cli).resolve()
    if not cyclonedx_cli_valid(cyclonedx_cli):
        raise FileNotFoundError(
            f"{cyclonedx_cli} not found or not functioning properly"
        )
    return cyclonedx_cli


def convert_single_file(
    cyclonedx_cli: Path, input_file_path: Path, output_file_path: Path
) -> bool:
    """Converts a single file from spdx.json to cyclonedx.json.
    Returns true if the return code of cycleclonedx cli was 0, false otherwise"""
    s = subprocess.run(
        [
            cyclonedx_cli,
            "convert",
            "--input-format",
            "spdxjson",
            "--output-format",
            "json",
            "--input-file",
            input_file_path.resolve(),
            "--output-file",
            output_file_path.resolve(),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if s.returncode != 0:
        logger.error(f"Failed to convert {input_file_path}")
        logger.debug(s.stdout.decode("ascii"))
        logger.debug(s.stderr.decode("ascii"))
    if s.returncode == 0:
        logger.debug(f"Converted successfully {input_file_path}")
    return s.returncode == 0


def convert_directory(
    cyclonedx_cli: Path, input_directory: Path, output_directory: Path
):
    input_directory = input_directory.resolve()
    if not input_directory.is_dir():
        logger.error(f"{input_directory} is not a valid directory")
        sys.exit(2)

    output_directory = output_directory.resolve()
    if not output_directory.exists():
        os.makedirs(output_directory)

    def pool_task(spdx_file: Path):
        new_name = spdx_file.name.replace(".spdx.json", ".json")
        full_output_path = output_directory / new_name

        if full_output_path.exists() and full_output_path.is_file():
            logger.warning(f"Skipping {spdx_file} as it is already converted")
            return True
        convert_single_file(cyclonedx_cli, spdx_file, full_output_path)

    spdx_files = input_directory.glob("*.spdx.json")
    with Pool() as pool:
        pool.map(pool_task, spdx_files)


def cli_args():
    parser = argparse.ArgumentParser(
        prog="SBOM Converter",
        description="Batch converts a directory containing SPDX files to CycloneDX format in parallel.",
        epilog=(
            "Uses the cyclonedx-cli as a base to convert single files.\
        Requires the binary is either available in PATH as cyclonedx or the environmental variable CYCLONEDX_CLI to be set pointing to it.\
        The cyclonedx binary can be downloaded from the official GitHub repository of the project: https://github.com/CycloneDX/cyclonedx-cli/releases."
        ),
    )
    parser.add_argument(
        "INPUT_DIR",
        help="Directory containing the SPDX *.spdx.json files to be converted",
        type=Path,
    )
    parser.add_argument(
        "OUTPUT_DIR",
        help="Directory where the converted CycloneDX *.json files will be saved",
        type=Path,
    )
    return parser.parse_args()


def main():
    try:
        cyclonedx_cli = get_cyclonedx_cli()
    except Exception as ex:
        logger.error(ex)
        logger.error(
            "cyclonedx binary not found. Please add it to PATH or set the "
            "CYCLONEDX_CLI environmental variable with the correct path.\n"
            "The binary for CycloneDX-cli can be found in the official releases:\n"
            "https://github.com/CycloneDX/cyclonedx-cli/releases"
        )
        sys.exit(1)  # could not find cli, abort

    args = cli_args()
    input_dir = args.INPUT_DIR.resolve()
    output_dir = args.OUTPUT_DIR.resolve()
    logger.info(f"Converting {input_dir} from SPDX to CycloneDX. Output: {output_dir}")
    convert_directory(cyclonedx_cli, input_dir, output_dir)
    logger.info("Done.")


if __name__ == "__main__":
    main()
