#!/bin/bash

set -euo pipefail

croncmd="$HOME/bin/rtstop > $HOME/bin/rtstop.log 2>&1"
cronjob="* * * * * $croncmd"
git config --global url."https://github.com/".insteadOf git://github.com

#Perform Checks

if [ ! -d "$HOME"/.local ]
then
  mkdir -p "$HOME"/.local
fi

if [ ! -d "$HOME"/.local/pyroscope ]
then
  git clone "https://github.com/pyroscope/pyrocore.git" "$HOME"/.local/pyroscope
  "$HOME"/.local/pyroscope/update-to-head.sh
  source "$HOME"/.profile
  pyroadmin --create-config
fi

##Create script

script="$HOME"/bin/rtstop

touch "$script" && chmod +x "$_"
cat <<'EOF' | tee "$script" >/dev/null
#!/bin/bash
"$HOME"/bin/rtcontrol is_complete=yes is_open=yes is_private=no ratio=+2 --stop
"$HOME"/bin/rtxmlrpc session.save
exit
EOF

##Create Crontab
( crontab -l | grep -v -F "$croncmd" || : ; echo "$cronjob" ) | crontab -

#Disable rtcheck
"$HOME"/bin/rtxmlrpc session.save
sed -i '/rtcheck/ s/method/#method/g' "$HOME"/.rtorrent.rc && app-rtorrent restart

exit
