#!/bin/bash
#
# To run Kanto-CM on top of an existing containerd/docker of the host,
# we need to share some of the folders, as filesystem paths are shared, e.g. kanto-cm telling runc to use "/var/lib/container-management/containers/hosts"
#
# Kanto Container Managment and containerd must be installed (but not running?) on the HOST!
# /var/lib/docker
# /var/lib/container-management/containers/
# /var/run/container-management for the libnetwork stuff

# mkdir -p /var/lib/container-management/containers/
# docker run -it --rm \
#     --privileged \
#     --network host \
#     -v /var/lib/docker:/var/lib/docker \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v /var/run/docker/containerd/containerd.sock:/var/run/docker/containerd/containerd.sock \
#     -v /var/run/container-management:/var/run/container-management \
#     -v /var/lib/container-management:/var/lib/container-management \
#     leda-test-debian11

docker run -it --rm --privileged leda-test-debian11



