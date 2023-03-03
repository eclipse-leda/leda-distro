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

## Guest Commands

### Installing RAUC Update

1. Run Leda Docker Devshell

    docker compose run devshell

2. SSH into the Leda guest

    ssh leda-x86

3. Switch to the data directory

    cd /data/selfupdates

4. Download the update bundle

    wget http://leda-bundle-server/sdv-rauc-bundle-minimal-qemux86-64.raucb
    wget http://leda-bundle-server/sdv-rauc-bundle-minimal-qemuarm64.raucb

5. Run the RAUC install

    rauc install sdv-rauc-bundle-minimal-qemux86-64.raucb
    rauc install sdv-rauc-bundle-minimal-qemuarm64.raucb

6. Mark the other partition as active

    rauc status mark-active other
    reboot now

7. You will return to devshell. Wait and reconnect to guest

    ssh leda-x86
    rauc status

## Running Robot Tests

To execute the Robot Framework tests, run the `leda-tests` docker compose service:

    ./test-docker.sh

This will rebuild the container (in case the tests have been changed) and run Robot.

The tests assume to be run inside of a container which is part of the `leda-network` environment.

Each test suite (e.g. each separate `*.robot` file) is executed in a new, clean docker container.

To execute only a single test suite, run the script with the test suite filename:

    ./test-docker.sh 01__base.robot

### Test Reports

The test reports will be located on the host in `./leda-tests-reports` in the current working directory.
The root contains merged overall reports (all test suites) in HTML and XML (Robot and xUnit) formats:

- `/report.html` - Main test report
- `/log.html` - Detailed robot test execution logs
- `/output.xml` - In Robot XML format
- `/leda-tests-xunit.xml` - In xUnit report format

Each test suite subfolder contains the following detailed reports:

- `/<TESTSUITE>/<MACHINE>/leda-tests-debug.log` - Robot Test Execution Steps Debug Output
- `/<TESTSUITE>/<MACHINE>/leda-tests-xunit.xml` - xUnit Report
- `/<TESTSUITE>/<MACHINE>/log.container-management.txt` - Syslog Journal of systemd service `container-management` (Eclipse Kanto)
- `/<TESTSUITE>/<MACHINE>/log.containerd.txt` - Syslog Journal of service `containerd` (system)
- `/<TESTSUITE>/<MACHINE>/log.dbus.txt` - Syslog Journal of service `dbus` (D-Bus system)
- `/<TESTSUITE>/<MACHINE>/log.html` - Robot HTML log report of detailed test execution steps
- `/<TESTSUITE>/<MACHINE>/log.kanto-auto-deployer.txt` - Syslog Journal of service `kanto-auto-deployer` (Eclipse Leda)
- `/<TESTSUITE>/<MACHINE>/log.rauc-mark-good.txt` - Syslog Journal of service `rauc-mark-good` (RAUC Mark-Good Service)
- `/<TESTSUITE>/<MACHINE>/log.rauc.txt` - Syslog Journal of service `rauc` (RAUC Update Service)
- `/<TESTSUITE>/<MACHINE>/mqtt-debug.log` - All recorded MQTT messages on the local MQTT broker during the test suite execution
- `/<TESTSUITE>/<MACHINE>/output.xml` - Robot Report in XML format of Test Suite
- `/<TESTSUITE>/<MACHINE>/report.html` - Robot HTML Report of Test Suite

