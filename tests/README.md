# Smoke Tests

This folder contains smoke tests for Eclipse Leda

- `src/robot/` - Robot Framework tests which can be executed locally against a target running with runqemu
- `src/tests_bash` - Shell scripts for testing various aspects

Note that the automated black box and system tests are now using the Docker Compose setup, which is located in the following location:

- `../resources/docker-snapshot/leda-tests/` - Robot Framework tests executed in a dockerized test environment

Note: The old Rust-based system tests have been replaced by the Robot tests.
