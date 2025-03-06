#!/bin/bash


set -a
source .env
set +a

DATE=`date +%Y-%m-%d"_"%H_%M_%S`

mkdir -p backup_$SITE_ENV"_"$DATE/user-uploads/
mkdir -p backup_$SITE_ENV"_"$DATE/user-guides/
mkdir -p backup_$SITE_ENV"_"$DATE/db/



docker exec -t picklebook-db mariadb-dump -uroot -p${DB_ROOTPASSWORD} picklebook > backup_$SITE_ENV"_"$DATE/db/picklebook.sql

cp -R /var/lib/docker/volumes/picklebook-user-uploads/_data/* backup_$SITE_ENV"_"$DATE/user-uploads/
cp -R /var/lib/docker/volumes/picklebook-user-guides/_data/* backup_$SITE_ENV"_"$DATE/user-guides/

tar -czf backup_$SITE_ENV"_"$DATE.tar.gz backup_$SITE_ENV"_"$DATE


rm -rf backup_$SITE_ENV"_"$DATE

curl -T backup_$SITE_ENV"_"$DATE.tar.gz "ftp://ftp.zwahlen.co.uk:2121/$SITE_ENV/" --user "${BACKUP_FTP_USERNAME}:${BACKUP_FTP_PASSWORD}"

rm -rf backup_$SITE_ENV"_"$DATE.tar.gz
