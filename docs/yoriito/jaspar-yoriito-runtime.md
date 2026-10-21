# Yoriito Kura at runtime on Eclipse Leda

## Installation in Leda

- Kura binary is already pre-installed as system binary and as a systemd service unit which starts automatically at boot.
- You can just start it manually and point it to a config file, the default location is `/etc/yoriito/viss/config.yml`

## Service management and logs

The native deployment starts automatically. Run these commands in the guest:

```sh
systemctl is-enabled kura.service
systemctl is-active kura.service
systemctl restart kura.service
journalctl -u kura.service -b --no-pager
```

Stop the native service before starting another Kura instance:

```sh
systemctl stop kura.service
```

To run it manually for debugging, keep the service stopped and use:

```sh
kura --config-file-path /etc/yoriito/viss/config.yml
```

Stop the manual process before restoring the managed service with
`systemctl start kura.service`.

## Installed commands and transport

| Command | Location | Purpose |
| --- | --- | --- |
| `kura` | `/usr/bin/kura` | VISS server, normally managed by systemd |
| `vshot` | `/usr/bin/vshot` | CLI, interactive REPL, and TUI client |

The pinned Kura implementation exposes the Yoriito gRPC consumer API on
`127.0.0.1:50052` and producer API on `127.0.0.1:50053`. The `vshot` defaults
match these endpoints; no connection options are needed in the guest.
These are not HTTP/JSON endpoints for `curl`. The pinned implementation
does not provide an HTTP controller, despite reserving an `http` Cargo
feature name. Use `vshot` for the Leda smoke test, rather than guessing an
HTTP URL. Host-to-guest port forwarding alone cannot expose a service bound
to guest loopback.

Status of Kura systemd service:
```bash
$ systemctl status kura
* kura.service - Yoriito VISS Server: KURA
     Loaded: loaded (/usr/lib/systemd/system/kura.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-10-20 22:44:40 UTC; 10min ago
 Invocation: 40f72b7b005a48c48780c4db29e6a6ff
   Main PID: 376 (kura)
      Tasks: 5 (limit: 4699)
     Memory: 10.5M (peak: 12.4M)
        CPU: 150ms
     CGroup: /system.slice/kura.service
             `-376 /usr/bin/kura --config-file-path /etc/yoriito/viss/config.yml

Oct 20 22:44:40 leda-525400123502 systemd[1]: Started Yoriito VISS Server: KURA.
```

Kura server version:
```bash
$ kura --version
kura 0.1.0
```

Kura server command line arguments (in case you want to run it manually):
```bash
$ kura --help
Usage: kura [OPTIONS] --config-file-path <CONFIG_FILE_PATH>

Options:
  -c, --config-file-path <CONFIG_FILE_PATH>
          relative path to config yml file. this is a path relative to one of the following absolute paths: 
          * home directory 
          * /etc/yoriito/viss 
          * /usr/local/etc/yoriito/viss 
          * current directory 

  -v, --verbose
          

  -f, --fake-platform
          

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

/etc/yoriito/viss/config.yml
```yaml
vss_path: vss.json
server_path: server.json
tick_resolution: 1000
```

/etc/yoriito/viss/server.json
```json
{
    "Server": {
        "children": {
            "Config": {
                "children": {
                    "AccessControl": {
                        "children": {
                            "AgtsUrl": {
                                "datatype": "string",
                                "description": "Access Grant Token Server URL including port number and path.",
                                "type": "attribute"
                            },

        <Rest of Server Configuration Schema>
```

Note: the server.json seems to be a schema and not meant to be for user editing.

/etc/yoriito/viss/vss.json
```json
{
  "Vehicle": {
    "children": {
      "ADAS": {
        "children": {
          "ABS": {
            "children": {
              "IsEnabled": {
                "datatype": "boolean",
                "description": "Indicates if ABS is enabled. True = Enabled. False = Disabled.",
                "type": "actuator"
              },

        <Rest of VSS JSON>
```

Note: The `vss.json` files can be generated using the vspec2json.py tool from COVESA vss-tools.

## vshot - the client cli

In the [Yoriito tutorial](https://docs.yoriito.dev/tutorials/07_develop_pal/07_develop_pal/),
you can find how to use vshot to change some vehicle signal values in Kura:

```
$ vshot tui                           # Use TUI mode
$ vshot -i                            # Use interactive mode
$ vshot get-current Vehicle.Speed     # Get the current value of Vehicle.Speed
$ vshot set-current Vehicle.Speed 100 # Set the current value of Vehicle.Speed to 100
```

The custom PAL layer (see Yoriito tutorial) will then translate between phyiscal CAN-Bus signals and VSS values.

In Eclipse Kuksa, the PAL layer is called "provider api", where customers are expected to implement their own signal providers (or feeders)
and connect them to Kuksa Databroker.

`vshot` in Eclipse Leda on qemu:

```bash
$ vshot get-current Vehicle.Speed
ts: 1792580059
data {
  data {
    path: "Vehicle.Speed"
  }
}

root@leda-525400123502:~# vshot set-current Vehicle.Speed 100
$ vshot get-current Vehicle.Speed
ts: 1792580066
data {
  data {
    path: "Vehicle.Speed"
    dp {
      value {
        float: 100
      }
    }
  }
}
```

Before a value is set, a response can contain the signal path without a
datapoint. After the write above, the returned float value should be `100`.
This changes the example broker's in-memory state; it does not actuate a
vehicle unless a separately configured PAL connects it to real hardware.

### Subscriptions

The following command names and arguments are verified against the pinned
client source. The user has confirmed subscriptions work on Leda; the
subscription response itself is not captured here because its identifiers
and timestamps vary.

Keep a subscription session open in one guest terminal:

```text
vshot -i
subscribe-current Vehicle.Speed
```

In another guest terminal, change the value:

```sh
vshot set-current Vehicle.Speed 101
```

Observe the update in the subscription session. To cancel it, use
`unsubscribe-current <subscription-id>` in that session, using the identifier
reported by the server. Exit the REPL with `:q`.
For an interactive UI, run `vshot tui` outside the REPL.

### Troubleshooting

- **`vshot: command not found`:** use the full image. The minimal and rescue
  images intentionally exclude Yoriito. Confirm the full-image manifest
  includes `vshot`, rebuild `sdv-image-all`, exit the old QEMU process, and
  relaunch `scripts/leda`; restarting a service does not replace a VM's disk.
- **Server is not running / connection refused:** check
  `systemctl status kura.service --no-pager` and the journal above. Inspect
  listeners with `ss -ltn`; both gRPC ports must be present. The CLI initializes
  both producer and consumer clients, including for a read command.
- **Address already in use:** do not start native and containerized Kura
  together, or a manual Kura process while its service is running.
- **No datapoint returned:** first set `Vehicle.Speed` as above. Do not
  interpret an unset value as a failed connection.
- **No space left on device:** inspect `df -h /` and `df -i /`. The full
  image reserves an additional 512 MiB; the bootable disk must also be rebuilt
  with `sdv-image-all`. A previously running VM retains its old disk.

## Container deployment

Native Kura remains the default. To build the alternative Kanto-managed
deployment, add the KAS overlay:

```sh
kas build kas/leda-qemux86-64.yaml:kas/yoriito-container.yaml
kas shell kas/leda-qemux86-64.yaml:kas/yoriito-container.yaml \
  -c 'runqemu slirp ovmf kvm nographic sdv-image-all'
```

Keep the overlay in the launch command: `scripts/leda` uses the native
configuration. Exit an existing VM before booting a newly built image.
Use a fresh bootable disk/data partition when changing deployment modes;
an existing persistent Kanto manifest is not removed by updating only the
rootfs slot.

The overlay sets `LEDA_YORIITO_DEPLOYMENT = "container"`. It disables
automatic startup of `kura.service`, retains guest-side `vshot`, and adds:

- an OCI image built by `sdv-image-kura` from the same patched `kura` recipe;
- a Docker-compatible archive at
  `/data/var/containers/images/kura-<sha256>.tar`, imported into the
  `kanto-cm` containerd namespace by the airgap installer;
- an enabled Kanto manifest at `/data/var/containers/manifests/kura.json`,
  selecting the local image `localhost/leda/kura:integration`.

The content hash in the archive filename prevents the installer's filename
cache from skipping a changed image. No registry pull is needed, and the
archive and its installer are included in container mode even if the other
airgap example containers are disabled.

Kura uses host networking to expose its loopback gRPC listeners to `vshot`.
It is not privileged and does not mount host directories. Configuration,
server schema, and VSS data are packaged into the container by the existing
recipes. The Kanto version used here has no read-only bind-mount field, so
the default descriptor deliberately avoids writable host configuration
mounts. Rebuild the OCI image to customize its configuration.

In the guest, inspect the deployment with:

```sh
systemctl is-enabled kura.service       # disabled in container mode
systemctl status airgap-container-installer.service --no-pager
systemctl status kanto-auto-deployer.service --no-pager
kanto-cm list                           # kura should be Running
journalctl -u container-management -u kanto-auto-deployer -b --no-pager
vshot get-current Vehicle.Speed
```

On a fresh QEMU x86-64 container-mode boot, Kanto reported `kura` as Running
while the native service was disabled. Writing `Vehicle.Speed` with
`vshot set-current Vehicle.Speed 123` and then reading it returned
`path: "Vehicle.Speed"` with `float: 123`.

Use `kanto-cm --help` for the installed CLI's stop/start/remove commands.
Do not start the native `kura.service` while the Kanto container is running.
For native mode, omit the overlay, rebuild `sdv-image-all`, and boot the new
disk rather than reusing a container-mode data partition.

To find out which TCP ports kura is listening on with leda built-in system networking tools:
```bash
$ ss -tulpen | grep kura
tcp   LISTEN 0      128         127.0.0.1:50053      0.0.0.0:*    users:(("kura",pid=714,fd=10))            ino:7389 sk:12 cgroup:/system.slice/kanto-cm-kura.scope/container <->       
tcp   LISTEN 0      128         127.0.0.1:50052      0.0.0.0:*    users:(("kura",pid=714,fd=9))             ino:5020 sk:13 cgroup:/system.slice/kanto-cm-kura.scope/container <-> 
```

This shows kura is listening on 127.0.0.1 for both TCP ports `50052` and `50053`:

| VISS/gRPC Port | Service Endpoint | Main Consumers / Clients | Primary Direction |
| --- | --- | --- | --- |
| 50052	| DataBroker Consumer API | HMI, Android/Linux Apps, Cloud Edge Libs subscribe to Vehicle signals to get current values, transmitting target values back into the databroker.	| Inbound reading / Outbound command intents |
| 50053	| DataBroker Producer API | PAL, ECUs, Vehicle Buses (CAN, Ethernet) feeding physical sensor values into the server (set current value), and polling for inbound command actions (when a consumer invokes set-target-value) | Inbound hardware telemetry / Outbound actuator targets |


