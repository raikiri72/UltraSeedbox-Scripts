#!/bin/bash

set -euo pipefail

croncmd="$HOME/bin/qbtcheck > $HOME/bin/qbtcheck.log 2>&1"
cronjob="* * * * * $croncmd"

#Get qBitttorrent Password

read -sp "Password of qBittorrent client: " password
echo

#Perform Checks

if [[ -z $(pip3 list | grep 'qbittorrent') ]]
then
  pip3 install -q qbittorrent-api
fi

#Create script

script="$HOME"/bin/qbtcheck

touch "$script" && chmod +x "$script"
cat <<'EOF' | tee "$script" >/dev/null
#!/usr/bin/env python3

import qbittorrentapi
import subprocess
import os

command = "app-ports show | grep qBittorrent | awk '{print $1}'"
port = subprocess.check_output(command, shell=True).decode('utf-8').strip()
username = os.getlogin()
password = '>pass<'

qbt = qbittorrentapi.Client(host=f'127.0.0.1:{port}', username={username}, password={password})

try:
    qbt.auth_log_in()
except qbittorrentapi.LoginFailed as e:
    print(e)

public_torrents=[]
all_torrents = qbt.torrents_info()

for torrent in all_torrents:
    if qbt.torrents_trackers(torrent.hash)[1].msg != "This torrent is private":
        public_torrents.append(torrent.hash)

qbt.torrents_set_share_limits(ratio_limit=2, seeding_time_limit=-1, torrent_hashes=public_torrents)
EOF
sed -i "s/>pass</$password/g" "$script"

#Create Crontab

( crontab -l | grep -v -F "$croncmd" || : ; echo "$cronjob" ) | crontab -

exit
