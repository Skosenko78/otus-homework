# **Введение**

Цель данной лабораторной работы изучить команды для установки и управления пакетами.

# **Создание RPM с определёнными опциями**

После запуска виртуальной машины все необходимые нам для работы пакеты уже установлены, rpm с исходниками скачаны, также скачаны и установлены необходимые зависимости.

Добавим опцию ```--with-openssl=/root/openssl-1.1.1l``` в секцию ```%build``` в файле ```/root/rpmbuild/SPECS/nginx.spec```

Произведём сборку RPM пакета:

```
[vagrant@repodemo ~]$ sudo -i
[vagrant@repodemo ~]$ rpmbuild -bb rpmbuild/SPECS/nginx.spec
...
Выполняется(%clean): /bin/sh -e /var/tmp/rpm-tmp.yChWIa
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.14.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.14.1-1.el7_4.ngx.x86_64
+ exit 0
```

Проверим, что пакеты создались:

```
[root@repodemo ~]# ll rpmbuild/RPMS/x86_64/
total 4584
-rw-r--r--. 1 root root 2158832 сен  2 13:18 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2528436 сен  2 13:18 nginx-debuginfo-1.14.1-1.el7_4.ngx.x86_64.rpm
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

Скопируем RPM файл с нашего сервера на сервер репозитория:

```
scp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm adminroot@185.189.68.218:/usr/share/nginx/html/repo/
```

Инициализируем репозиторий:

```
[adminroot@wvds132865] sudo createrepo /usr/share/nginx/html/repo/
```
Настроим в Nginx доступ к листингу каталогов, добавив директиву ```autoindex on``` в файл ```/etc/nginx/nginx.conf```

Перезапустим Nginx

```
nginx -s reload
```

Добавим новый репозиторий на локальной виртуальной машине. Для этого создадим файл ```/etc/yum.repo.d/oyus.repo``` со следующим содержанием: 

```
[otus]
name=otus-linux
baseurl=http://185.189.68.218
gpgcheck=0
enabled=1
```

Проверим наличие репозитория:

```
[vagrant@repodemo ~]$ yum repolist enabled | grep otus
Failed to set locale, defaulting to C
otus                                otus-linux                                1

[vagrant@repodemo ~]$ yum list | grep otus            
Failed to set locale, defaulting to C
nginx.x86_64                                1:1.14.1-1.el7_4.ngx       otus   
```

Запустим установку Nginx:

```
[vagrant@repodemo ~]$ sudo yum install -y nginx
...
Installed:
  nginx.x86_64 1:1.14.1-1.el7_4.ngx                                                                                                                   

Complete!

[vagrant@repodemo ~]$ sudo yum list | grep nginx
Failed to set locale, defaulting to C
nginx.x86_64                                1:1.14.1-1.el7_4.ngx       @otus    
pcp-pmda-nginx.x86_64                       4.3.2-13.el7_9             updates 
```


### **Заключение**

В процессе выполнения лабораторной работы были получены навыки сборки RPM пакетов, создания собственных репозитроиев и размещения RPM пакетов в эти репозитроии. Так же была проверена установка пакетов из этих репозитроиев.