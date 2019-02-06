#!/bin/bash

# check the script is run as root
if [ `whoami` != "root" ] ; then
  echo "ERROR: the installation program must be run by the 'root' user"
  exit 1
fi

# check the user home dir is specified
if [ ! -d "$1" ] ; then
  echo "ERROR: the script must be called with one parameter, the location of the user's home directory"
  exit 2
fi

# Install autovpn

user_dir="$1"
props="${user_dir}/.config/autovpn.properties"
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

# setup the properties file
function install_properties {
  # ...unless it already exists
  if [ ! -e "${props}" ] ; then
    mkdir -p "${user_dir}/.config"
    echo "# the location of the user's downloads folder monitored by autovpn" > ${props}
    echo "download_dir=${user_dir}/Downloads" >> ${props}
    chown `ls -ld ${user_dir}/ | awk '{print $3":"$4}'` "${user_dir}/.config" "${props}"
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
function install_unit_files {
  # stop the service if it is already installed
  if [ -f "${unit_dir}/autovpn.service" ] ; then
    systemctl stop autovpn.service
    systemctl disable autovpn.service
    systemctl daemon-reload
  fi

  echo 'Installing the autovpn systemd unit file'
  mkdir -p "${unit_dir}/autovpn.service.d"
  unit_env="${unit_dir}/autovpn.service.d/env.conf"
  echo "[Service]" > ${unit_env}
  echo "Environment=\"USER_HOME=${user_dir}\"" >> ${unit_env}
  echo "Environment=\"PROPS_FILE=${props}\"" >> ${unit_env}

  curl -so "${unit_dir}/autovpn.service" "${repo}/autovpn.service"
  systemctl daemon-reload
  systemctl start autovpn.service
  systemctl enable autovpn.service
}

install_prerequisits
install_properties
install_main_script
install_unit_files
