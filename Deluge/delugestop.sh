#!/bin/bash

set -euo pipefail

croncmd="$HOME/bin/delugechk > $HOME/bin/delugechk.log 2>&1"
cronjob="* * * * * $croncmd"

#Get Password

read -sp "Password of Deluge client: " password
echo

#Perform Checks

if [[ -z $(pip3 list | grep 'deluge-client') ]]
then
  pip3 install -q deluge-client
fi

#Create script

script="$HOME"/bin/delugechk

touch "$script" && chmod +x "$script"
cat <<'EOF' | tee "$script" >/dev/null
#!/usr/bin/env python3

from deluge_client import DelugeRPCClient
import subprocess
import os

command = "app-ports show | grep 'Deluge daemon' | awk '{print $1}'"
port = int(subprocess.check_output(command, shell=True).decode('utf-8').strip())
username = os.getlogin()
password = '>pass<'

client = DelugeRPCClient('127.0.0.1', port, username, password)
client.connect()

public_torrents=[]
all_torrents=client.call('core.get_torrents_status', {}, ['private', 'ratio'])
options= {'stop_at_ratio': True , 'stop_ratio': 2.0}

for hash, properties in all_torrents.items():
  if not properties[b'private']:
    public_torrents.append(hash.decode('utf-8'))

client.core.set_torrent_options(public_torrents,options)
EOF
sed -i "s/>pass</$password/g" "$script"

#Create Crontab

( crontab -l | grep -v -F "$croncmd" || : ; echo "$cronjob" ) | crontab -

exit
