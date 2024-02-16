FROM crops/poky:ubuntu-22.04


USER root
RUN useradd -ms /bin/bash pokyuser -g root -G sudo
RUN printf "password\npassword" | passwd pokyuser

USER pokyuser
WORKDIR /home/pokyuser

RUN mkdir -p ~/.bin
ENV PATH="${PATH}:${HOME}/.bin"
RUN wget -O ~/.bin/repo https://storage.googleapis.com/git-repo-downloads/repo
RUN chmod -R 777 ~/.bin/repo

USER root
RUN apt update

RUN apt install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa

RUN apt update
RUN export DEBIAN_FRONTEND=noninteractive
RUN DEBIAN_FRONTEND=noninteractive apt install -yq python2.7 python3.9 python3.9-distutils

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
# RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2
RUN update-alternatives --set python /usr/bin/python3.9

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
# RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2
RUN update-alternatives --set python3 /usr/bin/python3.9

RUN update-alternatives --install /usr/bin/python2 python2 /usr/bin/python2.7 1
RUN update-alternatives --set python2 /usr/bin/python2.7

RUN apt install curl clang lldb lld -y
RUN apt install gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev python3-subunit mesa-common-dev zstd liblz4-tool file locales -y
RUN locale-gen en_US.UTF-8

USER pokyuser
WORKDIR /workdir