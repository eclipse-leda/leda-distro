#!/bin/bash
sudo bash -c "echo \"deb file:${FULL_DIR} dracon main\" > /etc/apt/sources.list.d/sdv.list"
gpg --output public.key.gpg --export leda-dev@eclipse.org
# gpg --output private.pgp --armor --export-secret-key leda-dev@eclipse.org
# gpg --output public.pgp --armor --export leda-dev@eclipse.org
sudo cp public.key.gpg /etc/apt/trusted.gpg.d/
sudo apt update
apt search leda