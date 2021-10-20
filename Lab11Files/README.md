# **Введение**

Цель данной лабораторной работы получить навыки работы с инструментами настройки и управления SELinux.

## Описание

Стенд состоит из одного сервера 'Nginx' с ОС Centos 7.8. После старта стенда на сервере устанавливается Nginx и в конфиге указывается нестандартный порт 8085 для работы сервиса. IP адрес для проверки работы сервиса:

    http://10.0.0.41:8085

## **1. Запуск Nginx на нестандартном порту.**

После запуска стенда можно видеть, что nginx не запускается на порту 8085:

```
[vagrant@CustomNGPort ~]$ sudo systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[
```

Используем разные методы для устранения ошибки запуска сервиса.

## 1.1 Setsebool.

Утилита audit2why подсказывает нам, что нужно установить данную параметризованную политику:

    The boolean nis_enabled was set incorrectly.

```
[root@CustomNGPort vagrant]# getsebool nis_enabled
nis_enabled --> off
[root@CustomNGPort vagrant]# setsebool nis_enabled on
[root@CustomNGPort vagrant]# getsebool nis_enabled
nis_enabled --> on
```
И проверим запуск сервиса:

```
[root@CustomNGPort vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 12:52:03 UTC; 6s ago
  Process: 3418 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3416 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3415 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3420 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3420 nginx: master process /usr/sbin/nginx
           └─3422 nginx: worker process

Oct 20 12:52:03 CustomNGPort systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 12:52:03 CustomNGPort nginx[3416]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 12:52:03 CustomNGPort nginx[3416]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Oct 20 12:52:03 CustomNGPort systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Сервис запустился.

## 1.2 Добавление порта в имеющийся тип.

Вернём обратно настройку политики nis_enabled. Сервис опять не запускается. Добавим наш порт в имеющийся тип:

```
[root@CustomNGPort vagrant]# semanage port -l | grep http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

```
[root@CustomNGPort vagrant]# semanage port -a -t http_port_t -p tcp 8085
[root@CustomNGPort vagrant]# semanage port -l | grep http_port_t
http_port_t                    tcp      8085, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

И проверим запуск сервиса:

```
root@CustomNGPort vagrant]# systemctl start nginx
[root@CustomNGPort vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 13:06:10 UTC; 4s ago
  Process: 3775 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3773 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3772 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3777 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3777 nginx: master process /usr/sbin/nginx
           └─3779 nginx: worker process

Oct 20 13:06:10 CustomNGPort systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 13:06:10 CustomNGPort nginx[3773]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 13:06:10 CustomNGPort nginx[3773]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Oct 20 13:06:10 CustomNGPort systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Сервис запустился.

## 1.3 Формирование и установка модуля.

Удалим порт из типа http_port_t и попробуем сформировать модуль. Запустим утилиту  sealert и посмотрим как это можно сделать. Для запуска утилиты потребовалось изменить переменную окружения LANG=en_US.UTF-8.

```
You can generate a local policy module to allow this access.
Do allow this access for now by executing:
# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
# semodule -i my-nginx.pp
```

Выполним команды:

```
[vagrant@CustomNGPort ~]$ sudo ausearch -c 'nginx' --raw | audit2allow -M custom-nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i custom-nginx.pp

[vagrant@CustomNGPort ~]$ sudo semodule -i custom-nginx.pp
```

И попробуем запустить сервис:

```
[vagrant@CustomNGPort ~]$ sudo systemctl start nginx
[vagrant@CustomNGPort ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 13:38:06 UTC; 4s ago
  Process: 4753 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4750 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 4749 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4755 (nginx)
   CGroup: /system.slice/nginx.service
           ├─4755 nginx: master process /usr/sbin/nginx
           └─4757 nginx: worker process

Oct 20 13:38:06 CustomNGPort systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 13:38:06 CustomNGPort nginx[4750]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 13:38:06 CustomNGPort nginx[4750]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Oct 20 13:38:06 CustomNGPort systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Сервис запускается.

## **2. Диагностика работы приложения при включённом SELinux.**

При попытке удаленно (с рабочей станции) внести изменения в зону ddns.lab возникает ошибка `update failed: SERVFAIL` Появляется она по причине того, что процесс named на сервере работает в контексте безопасности named_t:

```
root@ns01 named]# ps -Z 715
LABEL                             PID TTY      STAT   TIME COMMAND
system_u:system_r:named_t:s0      715 ?        Ssl    0:00 /usr/sbin/named -u named -c /etc/named.conf
```

А каталог dynamic, в котором создаётся файл named.ddns.lab.view1.jnl находится в контексте безопасности etc_t:

```
[root@ns01 named]# ls -Z
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```

Решения:

1. Отключить SELinux.
2. Изменить контекст безопасности каталога dynamic
3. Сгенерировать модуль SELinux

Отключение не подходит, т.к. сервер должен быть защищён.Генерирование модуля даёт доступ процессу  named ко всем файлам сервера, у которых контекст безопасности etc_t, а он является базовым. Остановимся на изменении контекста безопасности только для конкретного каталога (вариант 2).

```
root@ns01 vagrant]# semanage fcontext -a -t named_zone_t '/etc/named/dynamic(/.*)?'
root@ns01 vagrant]# restorecon -v /etc/named/dynamic
```

После этого изменения в зону DNS с рабочей станции внеслись успешно:

```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
```

В файл настройки стенда внесены изменения. Добавлены действия по настройке сервера:

```
- name: Set selinux policy for dynamic dir
    sefcontext:
      target: '/etc/named/dynamic(/.*)?'
      setype: "named_zone_t"
      state: present

- name: Run restore context to reload selinux
    shell: restorecon -R -v /etc/named/dynamic
```