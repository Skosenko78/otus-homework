# **Введение**

Цель данной лабораторной работы изучить команды для установки и управления пакетами.

# **Создание RPM с определёнными опциями**

После запуска виртуальной машины все необходимые нам для работы пакеты уже установлены, rpm с исходниками скачаны, также скачаны и установлены необходимые зависимости.

Добавим опцию ```--with-openssl=/root/openssl-1.1.1l``` в секцию ```%build``` в файле ```/root/rpmbuild/SPECS/nginx.spec```

Произведём сборку RPM пакета:

```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
...
Выполняется(%clean): /bin/sh -e /var/tmp/rpm-tmp.yChWIa
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.14.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.14.1-1.el7_4.ngx.x86_64
+ exit 0
```

И проверим, что пакеты создались:

```
[root@bootdemo ~]# ll rpmbuild/RPMS/x86_64/
total 4584
-rw-r--r--. 1 root root 2158832 сен  2 13:18 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2528436 сен  2 13:18 nginx-debuginfo-1.14.1-1.el7_4.ngx.x86_64.rpm
```

Установим пакет и проверим запуск сервиса:

```
[root@bootdemo ~]# yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm

[root@bootdemo ~]# systemctl start nginx
[root@bootdemo ~]# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Чт 2021-09-02 13:25:05 UTC; 3s ago
     Docs: http://nginx.org/en/docs/
  Process: 19548 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 19549 (nginx)
   CGroup: /system.slice/nginx.service
           ├─19549 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─19550 nginx: worker process

```


# **Создание репозитория и размещение там RPM**

Репозиторий создадим на виртуальном сервере на платформе Websa.
Установим необходимые для работы пакеты:

```
sudo yum install -y nginx createrepo
```

Создадим каталог для репозитория:

```
[adminroot@wvds132865] sudo mkdir /usr/share/nginx/html/repo
```


### **Заключение**

В процессе выполнения лабораторной работы были получены навыки работы с файловой системой zfs. Были созданы тома, проверены функции импорта пулов и восстановления из snapshot'ов.