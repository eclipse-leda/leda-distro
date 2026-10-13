kas shell kas/leda-qemux86-64.yaml -c "bitbake -c clean container-management"
kas build kas/leda-qemux86-64.yaml
scripts/leda

Caching:
- Added Named volume:build/sstate-cache
- Added Named volume: build/downloads
- Removed: azure-sstate-cache
- Removed: azure-downloads-cache
Github WOrkflow:
- Removed azure-blob-storage-upload
- meta-lts-mixins repo duplicated in kas config, so that go AND rust can be mixed in

BROKEN:
- network
  - container image download
- sdv-motd does not mention sdv-help and blueprint-selector and kanto-auto-deployer etc.
- 

NEW IDEAS:
- Rename scripts/leda to leda-dev?
  put scripts/ into PATH
- create resources/eclipse-s-core/ ?

TODO:
- Create resources/debian/Dockerfile.debian13
- Remove AZURE_STORAGE_ACCESS_KEY
- Remove AZURE_STORAGE_ACCOUNT
- Remove mirros.yaml
- Remove generate-mirror.yaml
- Search for "siemens/kas" and replace with real name
- Update distro year and name
- github.repository_owner == 'SoftwareDefinedVehicle'
- .github/workflows/prebuild-sstate.yml
- BB_HASHSERVE = "bitbake-hashserv.westeurope.azurecontainer.io:1234"
- BB_HASHSERVE = "bitbake-hashserv.westeurope.azurecontainer.io:1234"
- MIRROR_SERVER = "https://sdvyocto.azureedge.net/downloads/"
- SSTATE_MIRRORS = "file://.* https://sdvyocto.azureedge.net/yocto-sstate-cache/sstate-cache/PATH"
- kas/common-kirkstone.yaml -> upgrade to wrynose
- kas: fix deprecated refspec
- low prio: meta-spdxscanner has an invalid license ("&")
- warning: preferred version 14.0.6 of llvm-native not available
- Build ERROR: ERROR: Task (/workspaces/leda-distro/build/../meta-kanto/recipes-containers/container-management/container-management_git.bb:do_compile) failed with exit code '1'
    -  module requires Go 1.19
    - search for GO_VERSION
- gibt es nicht mehr: ?!?!?!
  https://git.yoctoproject.org/git/meta-lts-mixins 



[2026-10-12T22:05:38Z ERROR kanto_auto_deployer] [CM error] Err(status: Unknown, message: "failed to resolve reference \"ghcr.io/eclipse-leda/leda-contrib-self-update-agent/self-update-agent:build-177\":failed to do request: Head \"https://ghcr.io/v2/eclipse-leda/leda-contrib-self-update-agent/self-update-agent/manifests/build-177\": dial tcp: lookup ghcr.io on 1.0.0.1:53: dial udp 1.0.0.1:53: connect: network is unreachable", details: [], metadata: MetadataMap { headers: {"content-type": "application/grpc"} })



2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-lts-mixins". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-rauc". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-kanto". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-virtualization". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-openembedded". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-spdxscanner". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-clang". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-leda". You should migrate to commit/tag/branch.
2026-10-12 16:06:08 - WARNING  - Using deprecated refspec for repository "meta-rauc-community". You should migrate to commit/tag/branch.


$ kas build kas/leda-qemux86-64.yaml
2026-10-12 16:38:36 - INFO     - kas 5.5 started on Debian GNU/Linux bookworm
2026-10-12 16:38:36 - INFO     - Running on VSCode Remote Containers
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "poky". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-lts-mixins". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-rauc". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-kanto". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-virtualization". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-openembedded". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-spdxscanner". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-clang". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-leda". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - WARNING  - Using deprecated refspec for repository "meta-rauc-community". You should migrate to commit/tag/branch.
2026-10-12 16:38:36 - INFO     - Repository poky already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-lts-mixins already contains kirkstone/rust-1.68 as commit
2026-10-12 16:38:36 - INFO     - Repository meta-rauc already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-kanto already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-virtualization already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-openembedded already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-spdxscanner already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-clang already contains kirkstone as commit
2026-10-12 16:38:36 - INFO     - Repository meta-leda already contains main as commit
2026-10-12 16:38:36 - INFO     - Repository meta-rauc-community already contains kirkstone as commit
2026-10-12 16:38:37 - INFO     - Repository poky checked out to kirkstone
2026-10-12 16:38:37 - INFO     - Repository meta-lts-mixins checked out to kirkstone/rust-1.68
2026-10-12 16:38:37 - INFO     - Repository meta-rauc checked out to kirkstone
2026-10-12 16:38:37 - INFO     - Repository meta-kanto checked out to kirkstone
2026-10-12 16:38:37 - INFO     - Repository meta-virtualization checked out to kirkstone
2026-10-12 16:38:38 - INFO     - Repository meta-openembedded checked out to kirkstone
2026-10-12 16:38:38 - INFO     - Repository meta-spdxscanner checked out to kirkstone
2026-10-12 16:38:38 - INFO     - Repository meta-clang checked out to kirkstone
2026-10-12 16:38:38 - INFO     - Repository meta-leda checked out to main
2026-10-12 16:38:38 - INFO     - Repository meta-rauc-community checked out to kirkstone
2026-10-12 16:38:38 - INFO     - /workspaces/leda-distro/build$ /workspaces/leda-distro/poky/bitbake/bin/bitbake -c build sdv-image-all
WARNING: You are running bitbake under WSLv2, this works properly but you should optimize your VHDX file eventually to avoid running out of storage space
Loading cache: 100% |                                                                                                                                                                                              | ETA:  --:--:--
Loaded 0 entries from dependency cache.
WARNING: /workspaces/leda-distro/build/../meta-spdxscanner/recipes-devtools/synopsys/synopsys-native_7.0.0.bb: QA Issue: synopsys-native: LICENSE value "Synopsys End User Software License & Maintenance Agreement" has an invalid format - license names must be separated by the following characters to indicate the license selection: &|()  [license-format]
WARNING: /workspaces/leda-distro/build/../meta-spdxscanner/recipes-devtools/synopsys/synopsys-native_7.0.0.bb: QA Issue: synopsys-native: LICENSE value "Synopsys End User Software License & Maintenance Agreement" has an invalid format - license names must be separated by the following characters to indicate the license selection: &|()  [license-format]
WARNING: /workspaces/leda-distro/build/../meta-spdxscanner/recipes-devtools/synopsys/synopsys-native_7.0.0.bb: QA Issue: synopsys-native: LICENSE value "Synopsys End User Software License & Maintenance Agreement" has an invalid format - license names must be separated by the following characters to indicate the license selection: &|()  [license-format]
WARNING: /workspaces/leda-distro/build/../meta-spdxscanner/recipes-devtools/synopsys/synopsys-native_7.0.0.bb: QA Issue: synopsys-native: LICENSE value "Synopsys End User Software License & Maintenance Agreement" has an invalid format - license names must be separated by the following characters to indicate the license selection: &|()  [license-format]
WARNING: /workspaces/leda-distro/build/../meta-spdxscanner/recipes-devtools/synopsys/synopsys-native_7.0.0.bb: QA Issue: synopsys-native: LICENSE value "Synopsys End User Software License & Maintenance Agreement" has an invalid format - license names must be separated by the following characters to indicate the license selection: &|()  [license-format]
Parsing recipes: 100% |#############################################################################################################################################################################################| Time: 0:00:09
Parsing of 2742 .bb files complete (0 cached, 2742 parsed). 4250 targets, 350 skipped, 10 masked, 0 errors.
NOTE: Resolving any missing task queue dependencies
WARNING: preferred version 14.0.6 of llvm not available (for item llvm)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm not available (for item llvm)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm not available (for item llvm-dev)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm not available (for item llvm-bugpointpasses)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm not available (for item llvm-llvmhello)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm not available (for item llvm-liboptremarks)
WARNING: versions of llvm available: 13.0.1
WARNING: preferred version 14.0.6 of llvm-native not available (for item llvm-native)
WARNING: versions of llvm-native available: 13.0.1

Build Configuration:
BB_VERSION           = "2.0.0"
BUILD_SYS            = "x86_64-linux"
NATIVELSBSTRING      = "debian-12"
TARGET_SYS           = "x86_64-poky-linux"
MACHINE              = "qemux86-64"
DISTRO               = "leda"
DISTRO_VERSION       = "2025"
TUNE_FEATURES        = "m64 core2"
TARGET_FPU           = ""
meta-clang           = "kirkstone:2942aec8f2c08d491d5703f0adae4c330b80bb55"
meta-kanto           = "kirkstone:2256fa056b644e2a06f2189f338abb45e19ae785"
meta-leda-bsp        
meta-leda-components 
meta-leda-distro     = "main:146044283feffa1f3ddcf9e7c6b91a1276e9c011"
meta-lts-mixins      = "kirkstone/rust-1.68:6b3a208f7e14138728a6e581ac75e8973ab48ef3"
meta-filesystems     
meta-networking      
meta-oe              
meta-python          = "kirkstone:ce8539c941f6fcbecaca4d16640ac105c0595589"
meta-rauc            = "kirkstone:4cb7c47686d5dec9bacae6110f1bcaac57568691"
meta-rauc-qemux86    = "kirkstone:05731f654511dc817d55e9cb02899efed3fe5bc3"
meta-spdxscanner     = "kirkstone:29fe84d965def4e290a7639fa79dddd890e64eb7"
meta-virtualization  = "kirkstone:92b6abcdfb6f12c4931247f0f29aaf5331984525"
meta                 
meta-poky            
meta-yocto-bsp       = "kirkstone:445a6223929b9a7a62b575093659e3d9e1aba982"

NOTE: Fetching uninative binary shim http://downloads.yoctoproject.org/releases/uninative/4.7/x86_64-nativesdk-libc-4.7.tar.xz;sha256sum=5800d4e9a129d1be09cf548918d25f74e91a7c1193ae5239d5b0c9246c486d2c (will check PREMIRRORS first)
Initialising tasks: 100% |##########################################################################################################################################################################################| Time: 0:00:02
Sstate summary: Wanted 2267 Local 0 Mirrors 0 Missed 2267 Current 0 (0% match, 0% complete)
NOTE: Executing Tasks
WARNING: gmp-native-6.2.1-r0 do_fetch: Failed to fetch URL https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2, attempting MIRRORS if available
WARNING: libxml-parser-perl-native-2.46-r0 do_fetch: Failed to fetch URL http://www.cpan.org/modules/by-module/XML/XML-Parser-2.46.tar.gz, attempting MIRRORS if available
WARNING: yocto-cfg-fragments-native-v5.14+git25509cd5563356638e78d33ec7e5354225fbd3db-r0 do_fetch: Failed to fetch URL git://git.yoctoproject.org/yocto-kernel-cache;branch=yocto-5.14, attempting MIRRORS if available
Setscene tasks: 2267 of 2267
