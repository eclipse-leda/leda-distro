# Eclipse Leda Build Resources

This folder containers additional resources for building and running Leda quickstart images using QEMU and Docker.

- `docker`- For users: Documentation explains how to start the Leda Quickstart Docker container
- `docker-compose` - For users: Documentation and docker compose setup, which starts multiple Leda containers including an update bundle webserver
- `docker-release` - For Leda developers: Building Leda docker container based on the latest public release of Leda (requires public release)
- `docker-snapshot` - For Leda developers: Building Leda docker container based on the current build working directory (local builds only, requires BitBake build environment)
- `runners`- For Leda developers: Additional scripts, documentation and other files needed to package the release archive
