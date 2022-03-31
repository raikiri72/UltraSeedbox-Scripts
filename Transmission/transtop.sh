#!/bin/bash

set -euo pipefail

croncmd="$HOME/bin/transchk > $HOME/bin/transchk.log 2>&1"
cronjob="* * * * * $croncmd"

#Get Password

read -sp "Password of Transmission client: " password
echo

#Perform Checks

if [[ -z $(pip3 list | grep 'transmission-rpc') ]]
then
  pip3 install -q transmission-rpc
fi

#Create script

script="$HOME"/bin/transchk

touch "$script" && chmod +x "$script"
cat <<'EOF' | tee "$script" >/dev/null
#!/usr/bin/env python3

from transmission_rpc import Client
import subprocess
import os

command = "app-ports show | grep 'Transmission web' | awk '{print $1}'"
port = int(subprocess.check_output(command, shell=True).decode('utf-8').strip())
username = os.getlogin()
password = '>pass<'

client = Client(host='127.0.0.1', port=port, username=username, password=password)

public_torrents=[]
all_torrents = client.get_torrents(arguments={'id', 'isPrivate'})

for torrent in all_torrents:
  if not torrent.isPrivate:
    public_torrents.append(torrent.id)

client.change_torrent(public_torrents, seedRatioLimit = 2, seedRatioMode = 1)
EOF
sed -i "s/>pass</$password/g" "$script"

#Create Crontab

( crontab -l | grep -v -F "$croncmd" || : ; echo "$cronjob" ) | crontab -

exit
