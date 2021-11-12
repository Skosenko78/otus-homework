#!/bin/bash

export BORG_PASSPHRASE='SecretKey'

if [ ! -d /var/backup/ClientRepo ]; then
    borg init -e=repokey /var/backup/ClientRepo && chown vagrant:vagrant -R /var/backup/ClientRepo
fi
