# **Введение**

Цель данной лабораторной работы настроить backup, получить навыки работы с утилитой Borg и её иструментами.

## Описание

Стенд состоит из двух серверов 'backup_server' с ОС Centos 7 и 'client' с ОС Centos 7. 

## 1. Backup папки /etc на сервере client

После старта стенда на сервере создаётся репозитроий ClientRepo (скрипт borgrepini.sh), а на client по таймеру systemd запускается backup папки /etc каждые 5 минут. Ниже приведена часть лога (/var/log/messages) с сервера client за 30 минут работы сервера:

```
Nov 12 07:38:12 localhost systemd: Started Regular task for backups creation script.
Nov 12 07:40:00 localhost systemd: Started Backup creation script.
Nov 12 07:40:00 localhost BorgBackup: Remote: Warning: Permanently added '10.0.0.41' (ECDSA) to the list of known hosts.
Nov 12 07:40:02 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_074000"
Nov 12 07:40:02 localhost BorgBackup: Synchronizing chunks cache...
Nov 12 07:40:02 localhost BorgBackup: Archives: 0, w/ cached Idx: 0, w/ outdated Idx: 0, w/o cached Idx: 0.
Nov 12 07:40:02 localhost BorgBackup: Done.
Nov 12 07:40:09 localhost BorgBackup: Keeping archive: 20211112_074000                      Fri, 2021-11-12 07:40:02 [5f76c03aa6c157201b566d26bad97cd9c7906eee402d6af14e864e47e8fb352c]
Nov 12 07:40:10 localhost BorgBackup: terminating with success status, rc 0
Nov 12 07:45:00 localhost systemd: Started Backup creation script.
Nov 12 07:45:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_074500"
Nov 12 07:45:06 localhost BorgBackup: Keeping archive: 20211112_074500                      Fri, 2021-11-12 07:45:01 [e050e56c3a9609241cbdc9df9c5bbdb1911870c80d37b5e40cb401c2930fdd0f]
Nov 12 07:45:06 localhost BorgBackup: Pruning archive: 20211112_074000                      Fri, 2021-11-12 07:40:02 [5f76c03aa6c157201b566d26bad97cd9c7906eee402d6af14e864e47e8fb352c] (1/1)
Nov 12 07:45:08 localhost BorgBackup: terminating with success status, rc 0
Nov 12 07:50:00 localhost systemd: Started Backup creation script.
Nov 12 07:50:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_075000"
Nov 12 07:50:06 localhost BorgBackup: Keeping archive: 20211112_075000                      Fri, 2021-11-12 07:50:01 [0151945107a65755675c5eab70930040e9464dd20d158ba2d9c75a1abefd1636]
Nov 12 07:50:06 localhost BorgBackup: Pruning archive: 20211112_074500                      Fri, 2021-11-12 07:45:01 [e050e56c3a9609241cbdc9df9c5bbdb1911870c80d37b5e40cb401c2930fdd0f] (1/1)
Nov 12 07:50:08 localhost BorgBackup: terminating with success status, rc 0
Nov 12 07:55:00 localhost systemd: Started Backup creation script.
Nov 12 07:55:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_075500"
Nov 12 07:55:06 localhost BorgBackup: Keeping archive: 20211112_075500                      Fri, 2021-11-12 07:55:01 [a5a8513970992cd405b826aec60199d79bcc1405701bb6dbd570a5328da00f93]
Nov 12 07:55:06 localhost BorgBackup: Pruning archive: 20211112_075000                      Fri, 2021-11-12 07:50:01 [0151945107a65755675c5eab70930040e9464dd20d158ba2d9c75a1abefd1636] (1/1)
Nov 12 07:55:08 localhost BorgBackup: terminating with success status, rc 0
Nov 12 08:00:00 localhost systemd: Started Backup creation script.
Nov 12 08:00:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_080000"
Nov 12 08:00:06 localhost BorgBackup: Keeping archive: 20211112_080000                      Fri, 2021-11-12 08:00:01 [9d093ff810d08c6ad56cb84fee68d0d0a26696d3e640da8fc2f7e0da766ee3a7]
Nov 12 08:00:06 localhost BorgBackup: Pruning archive: 20211112_075500                      Fri, 2021-11-12 07:55:01 [a5a8513970992cd405b826aec60199d79bcc1405701bb6dbd570a5328da00f93] (1/1)
Nov 12 08:00:08 localhost BorgBackup: terminating with success status, rc 0
Nov 12 08:05:00 localhost systemd: Started Backup creation script.
Nov 12 08:05:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_080500"
Nov 12 08:05:06 localhost BorgBackup: Keeping archive: 20211112_080500                      Fri, 2021-11-12 08:05:01 [63b4ad7f0b2b5366b301dcff207c7654a65f5ff9356a4d3cb34413b5deb39c27]
Nov 12 08:05:06 localhost BorgBackup: Pruning archive: 20211112_080000                      Fri, 2021-11-12 08:00:01 [9d093ff810d08c6ad56cb84fee68d0d0a26696d3e640da8fc2f7e0da766ee3a7] (1/1)
Nov 12 08:05:08 localhost BorgBackup: terminating with success status, rc 0
Nov 12 08:10:00 localhost systemd: Started Backup creation script.
Nov 12 08:10:01 localhost BorgBackup: Creating archive at "vagrant@10.0.0.41:/var/backup/ClientRepo::20211112_081000"
Nov 12 08:10:07 localhost BorgBackup: Keeping archive: 20211112_081000                      Fri, 2021-11-12 08:10:01 [d94be84393dfd9a7a025d8f7da0e26618e9de704d6b36c2490bb1897a2063787]
Nov 12 08:10:07 localhost BorgBackup: Pruning archive: 20211112_080500                      Fri, 2021-11-12 08:05:01 [63b4ad7f0b2b5366b301dcff207c7654a65f5ff9356a4d3cb34413b5deb39c27] (1/1)
Nov 12 08:10:09 localhost BorgBackup: terminating with success status, rc 0
```
В скрипте заданы условия удаления старых backup'ов. За последние 3 месяца копии должны быть за каждый день. Поэтому после создания нового backup, старый удаляется.
Результат работы скрипта переправляется в logger с тэгом 'BorgBackup'.


## 2. Восстановление из backup.

Проверим восстановление папки /etc из backup. Остановим таймер, который запускает наш скрипт:

```
[vagrant@Client ~]$ sudo systemctl stop backupborg.timer
```

Скопируем репозитроий на локальный сервер, т.к. после удаления папки /etc подключиться по ssh к серверу backup_server не получится:

```
[vagrant@Client ~]$ scp -r vagrant@10.0.0.41:/var/backup/ClientRepo ClientRepo
```

Перейдём в корневой каталог и удалим каталог /etc:

```
[vagrant@Client ~]$ sudo su -l
[root@Client ~]# cd /
[root@Client /]# rm -fR etc
rm: cannot remove ‘etc’: Device or resource busy
[root@Client /]# ls /etc
[root@Client /]#
```

Видно, что каталог /etc пуст. Восстановим его из нашего репозитория. Из лога можно увидеть, что последний (и единственный в нашем случае) созданный backup в репозитории называется '20211112_081000'. Укажем его в команде восстановления:

```
root@Client /]# borg extract /home/vagrant/ClientRepo::20211112_081000
Enter passphrase for key /home/vagrant/ClientRepo:
```
После указания пароля 'SecretKey' от репозитория  команда успешно отработала и данные в каталоге /etc восстановились:

```
[root@Client /]# ls /etc
adjtime                  dbus-1                   gshadow        login.defs         pkcs11            resolv.conf    sudoers
aliases                  default                  gshadow-       logrotate.conf     pki               rpc            sudoers.d
aliases.db               depmod.d                 gss            logrotate.d        pm                rpm            sudo-ldap.conf
alternatives             dhcp                     gssproxy       machine-id         polkit-1          rsyncd.conf    sysconfig
anacrontab               DIR_COLORS               host.conf      magic              popt.d            rsyslog.conf   sysctl.conf
audisp                   DIR_COLORS.256color      hostname       man_db.conf        postfix           rsyslog.d      sysctl.d
audit                    DIR_COLORS.lightbgcolor  hosts          mke2fs.conf        ppp               rwtab          systemd
bash_completion.d        dracut.conf              hosts.allow    modprobe.d         prelink.conf.d    rwtab.d        system-release
bashrc                   dracut.conf.d            hosts.deny     modules-load.d     printcap          samba          system-release-cpe
binfmt.d                 e2fsck.conf              idmapd.conf    motd               profile           sasl2          tcsd.conf
centos-release           environment              init.d         mtab               profile.d         securetty      terminfo
centos-release-upstream  ethertypes               inittab        my.cnf             protocols         security       tmpfiles.d
chkconfig.d              exports                  inputrc        my.cnf.d           python            selinux        tuned
chrony.conf              exports.d                iproute2       netconfig          qemu-ga           services       udev
chrony.keys              filesystems              issue          NetworkManager     rc0.d             sestatus.conf  vconsole.conf
cifs-utils               firewalld                issue.net      networks           rc1.d             shadow         virc
cron.d                   fstab                    krb5.conf      nfs.conf           rc2.d             shadow-        vmware-tools
cron.daily               fuse.conf                krb5.conf.d    nfsmount.conf      rc3.d             shells         wpa_supplicant
cron.deny                gcrypt                   ld.so.cache    nsswitch.conf      rc4.d             skel           X11
cron.hourly              gnupg                    ld.so.conf     nsswitch.conf.bak  rc5.d             ssh            xdg
cron.monthly             GREP_COLORS              ld.so.conf.d   openldap           rc6.d             ssl            xinetd.d
crontab                  groff                    libaudit.conf  opt                rc.d              statetab       yum
cron.weekly              group                    libnl          os-release         rc.local          statetab.d     yum.conf
crypttab                 group-                   libuser.conf   pam.d              redhat-release    subgid         yum.repos.d
csh.cshrc                grub2.cfg                locale.conf    passwd             request-key.conf  subuid
csh.login                grub.d                   localtime      passwd-            request-key.d     sudo.conf
[root@Client /]# 

```