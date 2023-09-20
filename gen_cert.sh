#!/bin/bash

# Generate SSL certificates for the domain
# (specified as the first command line parameter).
# Required for DNS Over HTTPS operation

sudo service apache2 stop
FULL_DOMAIN=${1}
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --register-unsafely-without-email -d "$FULL_DOMAIN"
sudo service apache2 start

echo "For AGH DNS Over HTTPS"
echo "PASTE IN FIRST TEXTAREA"
sudo cat /etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem
echo "                          "
echo "                          "
echo "                          "
echo "                          "
echo "PASTE IN SECOND TEXTAREA"
sudo cat /etc/letsencrypt/live/$FULL_DOMAIN/privkey.pem