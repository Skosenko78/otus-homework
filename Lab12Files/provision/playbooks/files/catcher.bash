#!/usr/bin/env bash

[ -e /etc/sysconfig/catcher ] && . /etc/sysconfig/catcher

if [[ $KEY_WORD != '' && $LOG_FILE != '' ]]; then
    date > /var/log/catcher.log
    grep $KEY_WORD $LOG_FILE >> /var/log/catcher.log
fi