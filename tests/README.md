# Smoke Tests

## Context
The project provides one or many quickstart images which consists of a variety of different software modules. These components are based on different programming languages and frameworks. In order to ensure the highest possible level of quality, it is important to test functionalities of the quickstart image (smoke/integration tests). These tests are a subset of test cases that cover the most important functionality of a system, used to aid assessment of whether main functions of the software appear to work correctly.

## Why we picked Rust
After, the team started working on writing OS tests in [Rust](https://www.rust-lang.org/). Compared to other frameworks, Rust seems to be good fit when it comes to cross compilation support, Yocto integration, and performance or stability. Therefore, it can be easility integrated into the existing SDV ecosystem stack.

### Cross Compilation using cargo cross
Rust supports a great number of [different platforms](https://doc.rust-lang.org/nightly/rustc/platform-support.html). We decided to start cross compiling our tests using [cross](https://github.com/cross-rs/cross) but may switch to `rustc` in the near future.

1. Install cargo

```bash
curl https://sh.rustup.rs -sSf | sh
```

2. Update the apt package index and install packages to allow `apt` to use a repo over HTTPS

```bash
 sudo apt-get update
 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```
3. Add Docker's official GPG key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

4. Set up the stable repo

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

5. Install the Docker Engine

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

6. Make sure that docker can be run from your current shell

```bash
sudo chmod 666 /var/run/docker.sock
```

7. Install `cargo cross`

```bash
cargo install cross --version 0.1.16
```
cross has the exact same CLI as Cargo but as it relies on Docker you'll have to start the daemon before you can use it.

8. Cross compile to X86_64

```
cross build --release --target x86_64-unknown-linux-musl
```

9. Running the tests locally and viewing test report
```
target/x86_64-unknown-linux-musl/release/leda-distro-tests
cat junit-results.xml
```

10. Deploy and run on device
Copy the tests binary `leda-distro-tests` to the device using secure copy and then remotely execute it:
```
# Note: Start qemu first
scp leda-distro-tests -P 2222 root@localhost:/home/root/         
ssh -p 2222 root@localhost "/home/root/leda-distro-tests"
scp -p 2222 root@localhost:/home/root/junit-results.xml ./
```


### How to write Tests
OSdistro tests are currently not written in Rust's common [test anatomy manner](https://doc.rust-lang.org/book/ch11-01-writing-tests.html). This is because `cargo` does not exist on the target platform, so that the output format cannot be customized.

We currently take advantage of [junit-report-rs](https://github.com/bachp/junit-report-rs) which generates JUnit compatible XML reports. The report can then be consumed by 3rd party plugins like GitHub Actions (e.g., [publish-unit-test-result-action](https://github.com/EnricoMi/publish-unit-test-result-action)).

We use [tokio's runtime](https://tokio.rs/) to handle all asynchronous tasks as it gives us the flexibility to target a wide range of platforms. If you want to add your custom tests, please make sure to implement the `TestParser` trait to your customs struct. The `run_test` function makes sure to return a `TestCase` which is necessary for creating the XML report. There are already multiple examples in the `tests` folder.

### Dependencies

Display dependency tree:
```
cargo tree --target x86_64-unknown-linux-musl
```

Updating dependencies:
```
cargo update
```

## To do
- Use Rust's native platform cross compiliation instead of `cargo cross`
- Reduce final binary size by removing dependencies we do not need anymore
- Implement async behavior so tests can run in parallel
- Implement platform-specific tests
- Use `cargo test` instead of `junit-report-rs`
- Added Command Line Params for passing platform-specific information