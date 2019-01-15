# autovpn

## Description
Monitor a user's `Downloads` folder for VPN config files and automatically use them to connect to a VPN.

## Installation
There is an installation script `install.sh` provided which should work for Ubuntu (and derivatives), and will hopefully give any other curious folk an idea of the manual steps required.
To run the installation script enter the following into a terminal:
```bash
curl -s 'https://raw.githubusercontent.com/RobinKnipe/autovpn/master/install.sh' | sudo bash -s
```
You can check everything worked with `sudo systemctl list-dependencies` - you should see something like the following example - note the `autovpn.service` unit is listed as the second item under the `default.target` (the dot next to it should _hopefully_ be green):
```bash
sudo systemctl list-dependencies
default.target
● ├─accounts-daemon.service
● ├─autovpn.service
...
```

## Configuration
When the service starts, it looks for a file `~/.config/autovpn.properties`. This file contains a few options to tailor the script:

### Download folder location
By default the monitored folder is: `"${HOME}/Downloads"`. To change it, add the `download_dir` property, as in the following example:
```properties
# look in "/tmp/downloads" instead
download_dir=/tmp/downloads
```

### VPN config filename regex pattern
By default any downloaded VPN file matching the general filename patter `*.ovpn` (regex: `.+\.ovpn`) will be connected. To change this add the `filename_pattern` property, as in the following example:
```properties
# only allow autovpn to connect to "my-connection.ovpn" and "some-other.ovpn"
filename_pattern='^(my-connection|some-other).ovpn$'
```
NOTE: The single quotes (') around the regex in the pattern are important.

### Download files to ignore pattern
By default Chromium's temporary files will be ignored (regex: `.*\.crdownload|\.org\.chromium\.Chromium\..*`). To change this add the `exclude_files` property, as in the following example:
```properties
# ignore all files with the extension ".part"
exclude_files=".*\.part"
```

### Auto-remove used VPN config files
By default the service will remove the VPN configuration files after it tries to connect, so that the downloads directory does not get unnecessarily cluttered. To disable this behaviour, set the `auto_remove` option to `no` or `false`.

### Important note
Simply making changes to the properties file will not take effect until the service restarts - this happens when the OS boots, or can be manualy triggered by running:
```bash
sudo systemctl restart autovpn.service
```

## Dependencies
The VPN connections are created using `openvpn` which must already be installed ([openvpn.net](http://openvpn.net)).

The `inotifywait` utility (from the `inotify-tools` package) is used to watch for new VPN configuration files, and is installed by the `install.sh` script.

This project has been built as a `systemd` service unit (`autovpn.service`), to handle automatic startup and give the necessary privileges to create VPN connections. The `autovpn` script could be configured to work with other system automation tools, please feel free to extend this project!

## Troubleshooting
You can find more information about the unit by running `systemctl status autovpn.service` in your terminal. The following snippet shows an example of the service running healthily, and the last two lines show two VPNs that were autoatically connected:
```bash
sudo systemctl status autovpn.service
● autovpn.service - Automatically connect to VPN after config download
   Loaded: loaded (/etc/systemd/system/autovpn.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2016-11-16 16:22:37 GMT; 1h 27min ago
 Main PID: 28928 (autovpn)
    Tasks: 5
   Memory: 3.3M
      CPU: 287ms
   CGroup: /system.slice/autovpn.service
           ├─28928 /bin/bash /usr/share/autovpn/autovpn
           ├─28930 inotifywait -mqe create --exclude .*\.crdownload|\.org\.chromium\.Chromium\..* /home/robin/Downloads
           ├─31287 openvpn --config /home/robin/Downloads/vpn-hod-platform-dev-20161116-1659.ovpn
           └─31549 openvpn --config /home/robin/Downloads/vpn-gro-lev-prod-20161116-1700.ovpn
```
The service also logs to the standard system log: `/var/log/syslog` - so there maybe more information there if you are experiencing problems.
