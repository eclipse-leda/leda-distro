#!/bin/bash

if [ ! -f gpg-unattended.conf ]; then
    echo "Creating GPG Key - and forcing GPG to use SHA256"
    echo "digest-algo sha256" >> ~/.gnupg/gpg.conf
cat >gpg-unattended.conf <<EOF
    %echo Generating a basic OpenPGP key
    %no-protection
    Key-Type: DSA
    Key-Length: 1024
    Subkey-Type: ELG-E
    Subkey-Length: 1024
    Name-Real: Eclipse Leda Contributors
    Name-Comment: with stupid passphrase
    Name-Email: leda-dev@eclipse.org
    Expire-Date: 0
    # Passphrase: abc
    # Do a commit here, so that we can later print "done" :-)
    %commit
    %echo done
EOF

    # Generating key
    gpg --batch --generate-key gpg-unattended.conf
else
    echo "Reusing GPG Key"
fi