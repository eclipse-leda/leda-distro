# For Eclipse Leda Developers - Docker Builds for Snapshots

This repository contains a docker-compose file and Dockerfiles for building Eclipse Leda Docker Container Images
and needed infrastructure within docker for testing and evaluation purposes.

Pre-Requisites:
- A finished, successfull Yocto build (`kas build`) for both QEMU X86-64 and QEMU ARM64
- A recent Docker and Docker Compose Plugin version (compose file is using build secrets).
- A potent host machine, e.g 16 vCPU, 32 GB RAM

## Building Container Images

Run the docker compose build

    kas build kas/leda-qemux86-64.yaml
    kas build kas/leda-qemuarm64.yaml
    ./build-docker.sh

## Publishing the Container Images

Login to ghcr.io:

    echo "${GITHUB_TOKEN}" | docker login --username "github" --password-stdin ghcr.io
    ./publish-docker.sh

## Docker Compose - General Usage

Starting up Docker Compose:

    ./run-docker.sh

Shutting down Docker Compose:

    ./stop-docker.sh
