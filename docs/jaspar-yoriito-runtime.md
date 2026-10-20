# Yoriito Kura at runtime on Eclipse Leda

- Kura binary is installed as system binary and as a systemd service unit which starts automatically at boot.
- You can just start it manually and point it to a config file, the default location is `/etc/yoriito/viss/config.yml`

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

```bash
$ kura --version
kura 0.1.0
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