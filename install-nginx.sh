#!/bin/bash

DOMAIN="matomo.abdellahi.tech"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NGINX_CONF_LINK="/etc/nginx/sites-enabled/$DOMAIN"
NGINX_CONF_CONTENT="server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if ! which nginx > /dev/null; then
    echo "Installing Nginx..."
    apt update
    apt install nginx -y
fi

if ! systemctl is-active --quiet nginx; then
    systemctl start nginx
fi

systemctl enable nginx

if [ ! -f "$NGINX_CONF" ]; then
    echo "Setting up Nginx configuration for $DOMAIN..."
    echo "$NGINX_CONF_CONTENT" > "$NGINX_CONF"
    ln -s "$NGINX_CONF" "$NGINX_CONF_LINK"
    echo "Nginx configuration setup complete."
else
    echo "Nginx configuration for $DOMAIN already exists."
fi

nginx -t && systemctl reload nginx
echo "Nginx configuration tested and reloaded."

if ! which certbot > /dev/null; then
    echo "Installing Certbot..."
    apt install certbot python3-certbot-nginx -y
fi

echo "Setting up SSL for $DOMAIN..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email your-email@example.com --redirect
echo "SSL setup complete."

CRON_JOB="0 12 * * * /usr/bin/certbot renew --quiet"
(crontab -l | grep -q "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Cron job for SSL renewal is set up."
