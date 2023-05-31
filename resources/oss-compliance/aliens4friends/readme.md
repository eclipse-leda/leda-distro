# Eclipse Oniro IP Compliance Toolchain

Scans an existing BitBake build directory and generates license compliance reports.

It uses two tools:
- TinfoilHat to generate metadata (`*.tinfoilhat.json`)
- Aliensrc Creator to package sources as `.aliensrc` tar balls, which include metadata (`aliensrc.json`) and source files of the original package

## Usage

1. Optional: Run a `kas` build with enabled remote mirrors, and one for downloading all sources

    kas build kas/leda-qemux86-64.yaml:kas/mirrors.yaml
    kas build kas/leda-qemux86-64.yaml:kas/mirrors.yaml -- --runall=fetch

2. Run a `kas` build with enabled generation of source tar balls:
    
    kas build kas/leda-qemux86-64.yaml:kas/oss-compliance/tinfoilhat.yaml

3. Run the Tinfoilhat-Container

    ./run-docker.sh

4. Check output directory:

    ls build/tmp/deploy/tinfoilhat

5. Run aliens4friends:

   ./run-aliens4friends.sh

6. Open fossology at http://127.0.0.1:8999

## Troubleshooting

### Unable to build aliens4friends fossology container

Replace `FROM fossology/fossology:3.9.0`

with: `FROM fossology:3.9`

### Unsupported SOURCE_MIRROR_URLs

Error message:
```
Got error TinfoilHatException: SOURCE_MIRROR_URLs with url scheme other than 'file://' (like https://sdvyocto.azureedge.net/downloads/) are not supported yet, sorry
```

Resolution: Remove the `mirrors.yaml` from the kas execution, or modify it to remove the source mirrors.

### Missing downloads

Error message:
```
Got error TinfoilHatException: can't find https://launchpad.net/debian/+archive/primary/+files/base-passwd_3.5.29.tar.gz in any of ['/workspaces/leda-distro-fork/build/downloads/'], something's wrong with recipe 'base-passwd'
```

Resolution: Run a BitBake fetch for the sources with enabled `BB_GENERATE_MIRROR_TARBALLS = "1"`

```
kas build kas/leda-qemux86-64.yaml:kas/oss-compliance/tinfoilhat.yaml -- --runall=fetch
```
