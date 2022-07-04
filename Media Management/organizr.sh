#!/bin/bash

printf "\033[0;31mDisclaimer: This installer is unofficial and Ultra.cc staff will not support any issues with it.\033[0m\n"
read -rp "Type confirm if you wish to continue: " input
if [ ! "$input" = "confirm" ]
then
    exit
fi

#Install nginx conf

cat << EOF | tee "${HOME}/.apps/nginx/proxy.d/organizr.conf" > /dev/null
location /organizr/ {
    auth_basic off;
    location ~ \.php$ {
    fastcgi_pass   unix:/etc/seedbox/user/${USER}/var/php7.0-fpm.sock;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
    }
}

location /organizr/api/v2 {
  try_files \$uri /organizr/api/v2/index.php\$is_args\$args;
  proxy_set_header Host \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-Proto https;
  proxy_redirect off;
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection \$http_connection;
}
EOF

#Restart Nginx

app-nginx restart

#Install Organizr

if [ -d "${HOME}/www/organizr" ];then
  echo
  echo "Organizr already exists, the nginx configuration has been re-added."
  echo
  exit 1
fi

git clone https://github.com/causefx/Organizr.git "${HOME}/www/organizr"

if [ ! -d "${HOME}/.apps/organizr" ]; then
   mkdir -p "${HOME}/.apps/organizr"
fi

DB_PATH=$(readlink -f "${HOME}/.apps/organizr")

echo
echo "Set the Database Location of Organizr to ${DB_PATH}"
echo
echo "Remember to create a strong password for your Organizr admin account."
echo
echo "You should now proceed to the ORGANIZR SETUP WIZARD via https://${USER}.${HOSTNAME}.usbx.me/organizr"
echo