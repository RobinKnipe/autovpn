#!/bin/bash

# check the script is run as root
if [ `whoami` != "root" ] ; then
  echo "ERROR: the installation program must be run by the 'root' user"
  exit 1
fi

# Install autovpn

user_dir="$1"
repo="https://raw.githubusercontent.com/RobinKnipe/autovpn/master/"
script_dir=/usr/share/autovpn
unit_dir=/etc/systemd/system

# ensure the "inotify-tools" package is installed
function install_prerequisits {
  if ! which inotifywait > /dev/null ; then
    echo 'Installing inotify-tools package'
    apt update
    apt install -y inotify-tools
  fi
}

# download the main autovpn script file
function install_main_script {
  echo 'Installing the main autovpn script file'
  mkdir -p "${script_dir}"
  curl -so "${script_dir}/autovpn" "${repo}autovpn"
  chmod +x "${script_dir}/autovpn"
}

# download and activate the autovpn systemd unit
function install_unit_file {
  echo 'Installing the autovpn systemd unit file'
  mkdir -p ${unit_dir}
  curl -so "${unit_dir}/autovpn.service" "${repo}/autovpn.service"
  systemctl daemon-reload
  systemctl start autovpn.service
  systemctl enable autovpn.service
}

install_prerequisits
install_main_script
install_unit_file
