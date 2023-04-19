FROM debian

# Update packages
RUN apt-get update

# Install BitBake and Tinfoilhat Dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends socat file gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
        iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \ 
        mesa-common-dev zstd liblz4-tool tmux mc ca-certificates curl python3-yaml rsync rpm unzip xz-utils lzip git

# Install Tinfoilhat
RUN git clone https://gitlab.eclipse.org/eclipse/oniro-compliancetoolchain/toolchain/tinfoilhat.git
RUN cp tinfoilhat/tinfoilhat.py /usr/bin/tinfoilhat && chmod +x /usr/bin/tinfoilhat

WORKDIR /app
ADD tinfoilhat-entrypoint.sh /app

VOLUME [ "/workspace" ]

ENTRYPOINT [ "/app/tinfoilhat-entrypoint.sh" ]
