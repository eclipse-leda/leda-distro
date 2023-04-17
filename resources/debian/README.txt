Eclipse Leda - Debian packages

Building Debian packages using BitBake to make packages installable on vanilla Debian distros (non-Poky based).

1. Building the packages

    Add to kas configuration:
    PACKAGE_CLASSES += " package_deb"

    Run a build
    kas build kas/leda-qemux86-64.yaml

2. Test the local repository

    Run install-local-repo.sh, which will add the ./repo-root/ to the apt sources.list
    Use apt search or apt install to install packages.
    Note: This will install on your host!

3. Create an Apt repository

    Setup gpg using generate-gpg-key.sh or reuse existing
    Run the repo-create.sh

    Ensure ${PROJET_ROOT}/azure-debian/ is mounted, or adapt upload-repo.sh
    Run the script to upload the Apt repository to a remote webserver.

4. Test with Docker

    Run the build-docker.sh which will build container images with predefined Apt remote repository.
    The build will fail if it cannot install any of the SDV Core components.

    Run the test-docker.sh to build for multiple target OS distros and run a small test script.
    The test script runs Mosquitto, DBUS, containerd and container-management and will then create 
    the SDV core containers.

    No functional testing is being done in this stage.
