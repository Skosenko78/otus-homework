#!/bin/bash
exec > >(logger -p local0.notice -t BorgBackup)
exec 2> >(logger -p local0.error -t BorgBackup)

export BORG_PASSPHRASE='SecretKey'
CLIENT=vagrant
SERVER=10.0.0.41
REPOSITORY=$CLIENT@$SERVER:/var/backup/ClientRepo
# Backup
borg create -v \
$REPOSITORY::$(date +%Y%m%d_%H%M%S) \
/etc
# After backup
borg prune -v --show-rc --list $REPOSITORY \
 --keep-daily=90 --keep-monthly=9