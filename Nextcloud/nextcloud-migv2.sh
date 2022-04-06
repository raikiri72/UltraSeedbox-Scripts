#!/bin/bash

####################################################################################################################
#First finish 2ndpass and ensure Nextcloud is the first application you attempt to restore.                        #
#Then run the command given below:                                                                                 #
#mv "$HOME"/.apps/nextcloud "$HOME"/.apps/nextcloud.bak                                                            #
#Do a fresh install of Nextcloud on the new slot till the MariaDB is connected and you login to Nextcloud properly.#
#Finally, run the script.                                                                                          # 
####################################################################################################################

set -euo pipefail

#Warning

printf "\033[0;31m!!!WARNING!!! Please make sure to input correct nextcloud db passwords. There is no way for the script to check these and inputting them incorrectly will not end well.\033[0m\n"
echo
printf "\033[0;31mImportant: 2ndpass should already be finished and you need to run the command [mv ~/.apps/nextcloud ~/.apps/nextcloud.bak]. After that you must do a fresh installation of NextCloud on the new slot and perform first time setup i.e connect the database and create any random user before running this script.\033[0m\n"
while true; do
  read -rp "Do you wish to continue? [Yes/No] " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

#Get Details

read -rp 'NextCloud DB Password Old Slot: ' nextcloud_old
echo
read -rp 'NextCloud DB Password New Slot: ' nextcloud_new
echo

#Get Oldslot details

read -rp 'Old slot username: ' uservar
read -rp 'Old slot servername[Example: myles]: ' server
servername=$server.usbx.me

#Dump Old Nextcloud DB

echo "Dumping NextCloud DB on Old slot.."
PASS=$nextcloud_old
ssh -T "${uservar}"@"${servername}" PASS="${PASS}" 'bash -s' <<'ENDSSH'
nextcloud_old=$PASS
app-nextcloud upgrade -p $nextcloud_old && sleep 20
app-nextcloud stop && sleep 10
app-mariadb restart && sleep 10
port=$(app-ports show | grep MySQL | awk {'print $1'})
mysqldump -P $port -h 127.0.0.1 -u nextcloud -p$nextcloud_old nextcloud > nextcloudbak.sql
mv nextcloudbak.sql "$HOME"/.apps/nextcloud/
ENDSSH
echo "Done!"

#Get files from Old slot

app-nextcloud stop
echo "Transferring files from Old slot to New slot.."
rsync -aHAXxv "${uservar}"@"${servername}":.apps/nextcloud/ "$HOME"/.apps/nextcloud.bak
echo "Done!"

#Restore NextCloud on New slot

echo "Restoring NextCloud.."
port=$(app-ports show | grep MySQL | awk '{print $1}')
rm -rf "$HOME"/.apps/nextcloud && mv "$HOME"/.apps/nextcloud.bak "$HOME"/.apps/nextcloud && cd "$HOME"/.apps/nextcloud
mysql -P "${port}" -h 127.0.0.1 -u nextcloud -p"${nextcloud_new}" -e "DROP DATABASE nextcloud"
mysql -P "${port}" -h 127.0.0.1 -u nextcloud -p"${nextcloud_new}" -e "CREATE DATABASE nextcloud"
mysql -P "${port}" -h 127.0.0.1 -u nextcloud -p"${nextcloud_new}" nextcloud <nextcloudbak.sql
app-nextcloud upgrade -p "${nextcloud_new}"
echo "Done!"

#Perform Cleanup
echo "Performing Cleanup.."
rm "$HOME"/.apps/nextcloud/nextcloudbak.sql
ssh -T "${uservar}"@"${servername}" 'bash -s' <<'ENDSSH'
rm "$HOME"/.apps/nextcloud/nextcloudbak.sql
app-mariadb stop
ENDSSH
echo "Done!"