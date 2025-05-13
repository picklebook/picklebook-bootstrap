#!/bin/bash

set -a
source .env
set +a

rm -rf mailcow-20*
rm -rf *.tar.gz

cd /opt/mailcow-dockerized/helper-scripts

export MAILCOW_BACKUP_LOCATION=/opt/mailcow-backup

./backup_and_restore.sh backup all --delete-days 1

cd /opt/mailcow-backup

DATE=`date +%Y-%m-%d"_"%H_%M_%S`

tar czf mailcowbackup-$DATE.tar.gz mailcow-20*

curl -k -T mailcowbackup-$DATE.tar.gz "sftp://ftp.picklebook.org:2022/MAILCOW/" --user "${BACKUP_FTP_USERNAME}:${BACKUP_FTP_PASSWORD}"
