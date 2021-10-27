# **Введение** #

Цель данной лабораторной работы получить навыки управления учётными записями и правами доступа.

## **Описание** ##

Стенд состоит из одного сервера 'PAM' с ОС Centos 7.8. После старта стенда настройка осуществляется с помощью Ansible.
1. На сервере создаются пользователи 'day', 'night', 'friday' с одинаковым паролем 'Otus2021'.
2. В файле /etc/ssh/sshd_config раскомментируется строчка `PasswordAuthentication yes`.
3. Копируется скрипт `test_login.sh` для проверки PAM аутентификации.

Разграничим доступ пользователей в систему по ssh в соответствии с условием:

- 'day' имеет доступ каждый день с 8 до 20
- 'night' доступ каждый день с 20 до 8
- 'friday' в любое время по пятницам

## **Модуль pam_time** ##

Настройки модуля pam_time хранятся в файле /etc/security/time.conf. Изменим его в соответствии с нашей задачей:

```
[vagrant@PAM ~]$ sudo tail -n 4 /etc/security/time.conf 
#
*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr0000-2400
```

Модуль pam_time по умолчанию не подключён к сервису sshd. Добавим его в файл /etc/pam.d/sshd:

```
...
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    required     pam_time.so
account    include      password-auth
password   include      password-auth
...
```

Проверим ssh подключение:

```
s_kosenko@linuxvb:~$ date
Ср 27 окт 2021 14:49:38 MSK
```

1. Пользователь 'day':

```
s_kosenko@linuxvb:~$ ssh -l day 10.0.0.41
The authenticity of host '10.0.0.41 (10.0.0.41)' can't be established.
ECDSA key fingerprint is SHA256:EYRRNHoIcTTbBWgCb9S722kLhsIXPGxCRGamKGtxTBk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.0.41' (ECDSA) to the list of known hosts.
day@10.0.0.41's password: 
Last login: Wed Oct 27 11:27:15 2021
[day@PAM ~]$
```
Подключение есть.

2. Пользователь 'night':

```
s_kosenko@linuxvb:~$ ssh -l night 10.0.0.41
night@10.0.0.41's password: 
Connection closed by 10.0.0.41 port 22
s_kosenko@linuxvb:~$ 
```

Доступа нет.

3. Пользователь 'friday':

```
s_kosenko@linuxvb:~$ ssh -l friday 10.0.0.41
friday@10.0.0.41's password: 
Connection closed by 10.0.0.41 port 22
s_kosenko@linuxvb:~$ 
```

Доступа нет.


## **Модуль pam_exec** ##

Реализовать задачу разграничения доступа пользователей в систему можно так же с помощью скрипта. Добавим в файл /etc/pam.d/sshd использование модуля pam_exec:

```
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    required     pam_exec.so /usr/local/bin/test_login.sh
account    include      password-auth
password   include      password-auth
```

Проверим подключение:

```
_kosenko@linuxvb:~$ date
Ср 27 окт 2021 15:14:22 MSK
s_kosenko@linuxvb:~
```

1. Пользователь 'day':

```
s_kosenko@linuxvb:~$ ssh -l day 10.0.0.41
day@10.0.0.41's password: 
Last login: Wed Oct 27 12:13:19 2021 from 10.0.0.1
[day@PAM ~]$
```

Доступ есть.

2. Пользователь 'night':

```
s_kosenko@linuxvb:~$ ssh -l night 10.0.0.41
night@10.0.0.41's password: 
/usr/local/bin/test_login.sh failed: exit code 1
Connection closed by 10.0.0.41 port 22
s_kosenko@linuxvb:~$ 
```

Доступа нет.

3. Пользователь 'friday':

```
s_kosenko@linuxvb:~$ ssh -l friday 10.0.0.41
friday@10.0.0.41's password: 
/usr/local/bin/test_login.sh failed: exit code 1
Connection closed by 10.0.0.41 port 22
s_kosenko@linuxvb:~$
```

Доступа также нет.

## **Модуль pam_script** ##

Для проверки работы модуля pam_script.so нам потребуется скопировать наш скрипт `test_login.sh`  в `pam_script_auth` и привести файл /etc/pam.d/sshd к следующему виду:

```
#%PAM-1.0
auth	   required	pam_sepermit.so
auth	   required  	pam_script.so onerr=success dir=/usr/local/bin/
auth       substack     password-auth
auth       include      postlogin
...
```

И проверим подключение:

1. Пользователь 'day':

```
s_kosenko@linuxvb:~$ ssh -l day 10.0.0.41
day@10.0.0.41's password: 
Last login: Wed Oct 27 13:51:41 2021 from 10.0.0.1
[day@PAM ~]$
```

Подключение есть.

2. Пользователь 'night':

```
s_kosenko@linuxvb:~$ ssh -l night 10.0.0.41
night@10.0.0.41's password: 
Permission denied, please try again.
night@10.0.0.41's password: 

s_kosenko@linuxvb:~$ 
```

Доступа нет.

3. Пользователь 'friday':

```
s_kosenko@linuxvb:~$ ssh -l friday 10.0.0.41
friday@10.0.0.41's password: 
Permission denied, please try again.
friday@10.0.0.41's password: 

s_kosenko@linuxvb:~$
```

Доступа нет.

## **Модуль pam_cap** ##

Необходимо разрешить пользователю 'day' выполнять команду `ncat`. Проверим возможность запуска:

```
[day@PAM vagrant]$ ncat -l -p 80
Ncat: bind to :::80: Permission denied. QUITTING.
[day@PAM vagrant]$
```

Пользователь 'day' не может выполнить команду, т.к. у этого пользователя нет полномочий открывать для прослушивания порт 80.

## SUID ##

Установим suid-бит на программу ncat. Для этого выполним:

```
[vagrant@PAM ~]$ sudo chmod u+s /usr/bin/ncat
vagrant@PAM ~]$ ls -l /usr/bin/ncat 
-rwsr-xr-x. 1 root root 380184 Aug  9  2019 /usr/bin/ncat
```

Теперь попробуем выполнить команду ещё раз:

```
[vagrant@PAM ~]$ su day
Password: 
[day@PAM vagrant]$ ncat -l -p 80


```

Команда ошибок не выдала и открыла порт 80 для прослушивания.
Но данный способ имеет низкую гибкость, т.к. позволяет выполнять команду с установленным SUID любому пользователю. Попробуем другой способ.

## Модуль pam_cap ##

Отредактируем файл /etc/pam.d/sshd:

```
#%PAM-1.0
auth	   required	pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
auth       required     pam_cap.so
```

Создадим файл /etc/security/capability.conf со строчкой:

```
cap_net_bind_service	day
```

И выдадим программе `ncat` такое же разрешение:

```
[vagrant@PAM ~]$ sudo setcap cap_net_bind_service=ei /usr/bin/ncat
```

Проверим наличие у пользователя необходимых прав при подключении по ssh:

```
s_kosenko@linuxvb:~$ ssh -l day 10.0.0.41
day@10.0.0.41's password: 
Last login: Wed Oct 27 14:10:23 2021
[day@PAM ~]$ capsh --print
Current: = cap_net_bind_service+i
```

И попробуем снова выполнить команду:

```
[day@PAM ~]$ ncat -l -p 80


```

Ошибки не возникло и порт октрылся для прослушивания. Проверим это из другой консоли:

```
[vagrant@PAM ~]$ echo "Make Linux greate again" > /dev/tcp/127.0.0.7/80

[day@PAM ~]$ ncat -l -p 80
Make Linux greate again
[day@PAM ~]$
```

## **Права администратора** ##

Помимо внесения ограничений на вход пользователя в систему, мы можем предоставить пользователю разные права. Дадим пользователю 'day' права root'а. Для этого можно просто добавить пользователя в группу 'wheel':

```
[vagrant@PAM ~]$ sudo usermod -G wheel day
```

Или внести пользователя в файл sudoers, либо создать файл, названный именем пользователя в каталоге /etc/sudoers.d/:

```
[vagrant@PAM ~]$ sudo visudo -f /etc/sudoers.d/day
[vagrant@PAM ~]$ sudo cat /etc/sudoers.d/day
day	ALL=(ALL)	ALL
[vagrant@PAM ~]$
```

Создание файла в каталоге /etc/sudoers.d/ является более гибким, удобным и предпочтительным вариантом.