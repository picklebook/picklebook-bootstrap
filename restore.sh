#!/bin/bash

if [" docker container inspect picklebook-db > /dev/null 2>&1" ]; then
    echo "Please stop picklebook-db container first."
    exit 1
fi

set -a
source .env
set +a

curl -o $2.tar.gz "ftp://ftp.zwahlen.co.uk:2121/$1/$2.tar.gz" --user "${BACKUP_FTP_USERNAME}:${BACKUP_FTP_PASSWORD}"

tar -xvzf $2.tar.gz



docker volume rm picklebook-mysql-data
docker volume rm picklebook-user-uploads
docker volume rm picklebook-user-guides

docker volume create picklebook-mysql-data
docker volume create picklebook-user-uploads
docker volume create picklebook-user-guides


cp $2/db/picklebook.sql .
cp -R $2/user-uploads/* /var/lib/docker/volumes/picklebook-user-uploads/_data/
cp -R $2/user-guides/* /var/lib/docker/volumes/picklebook-user-guides/_data/

chown -R www-data:www-data /var/lib/docker/volumes/picklebook-user-uploads/_data/
chown -R www-data:www-data /var/lib/docker/volumes/picklebook-user-guides/_data/


#Cleanup
rm -rf $2*
