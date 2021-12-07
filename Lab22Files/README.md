# **Введение** #

Цель данной лабораторной работы закрепить знания по настройке доменов, получить навыки работы с инструментами DNS, увидеть типы серверов, зон и т.д. на пратике.

## **Описание** ##

Стенд состоит из четырёх серверов с ОС Centos 7:

- 'ns01' главный (master) DNS сервер
- 'ns02' вторичный (slave) DNS сервер
- 'client1' первый клиент для проверки DNS зоны
- 'client2' второй клиент для проверки DNS зоны

## **Копирование стенда** ##

Стенд клонируется в рабочую папку с ресурса https://github.com/erlong15/vagrant-bind

## **Client 2** ##

Изначально в стенде описан 1 клиент. Добавим описание второго клиента в Vagrant файл:

```
config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    client2.vm.hostname = "client2"
  end
```
И добавим его настройку при старте стенда в файл 'playbook.yml'

## **Зона DNS dns.lab** ##

После запуска стенда добавим в зону 'dns.lab' записи. Для чего отредактируем файл 'named.dns.lab' на сервере ns01, добавив строки:

```
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
```
Так же увеличим параметр 2711201408 ; serial для того, что бы изменения передались на slave сервер и перегружаем сервис DNS на обоих серверах:

```
systemctl restart named
```

После перезапуска можем проверить резрешение имён через master DNS:

```
[vagrant@client1 ~]$ dig @192.168.50.11 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 22563
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15
...

```
И через slave DNS:

```
[vagrant@client1 ~]$ dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12502
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16
...

```

## **Зона newdns.lab** ##

Добавим новую DNS зону на master DNS (ns01):

В файл '/etc/named.conf' добавим секцию:

```
// lab's newdns zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
```

В каталоге '/etc/named/' создадим файл следующего содержания:

```
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.newdns.lab. root.newdns.lab. (
                            2711201408 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.newdns.lab.
                IN      NS      ns02.newdns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

www            IN      A       192.168.50.15
www            IN      A       192.168.50.16
```

На slave DNS (ns02) добавим секцию в файл '/etc/named.conf':

```
// lab's zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "slaves/named.newdns.lab";
};
```

И перезапустим сервис 'named' сначала на master DNS (ns01), затем на slave DNS (ns02).

Проверим резрешение имён домена newdns.lab:

```
[vagrant@client2 ~]$ dig @192.168.50.10 www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55908
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.16
www.newdns.lab.		3600	IN	A	192.168.50.15

....
```

Теперь опросим slave DNS (ns02):

```
[vagrant@client2 ~]$ dig @192.168.50.11 www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13166
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.16
www.newdns.lab.		3600	IN	A	192.168.50.15
...

```
```
[vagrant@client1 ~]$ ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client1 (192.168.50.15): icmp_seq=1 ttl=64 time=0.029 ms
64 bytes from client1 (192.168.50.15): icmp_seq=2 ttl=64 time=0.074 ms
64 bytes from client1 (192.168.50.15): icmp_seq=3 ttl=64 time=0.181 ms
...
```

```
[vagrant@client2 ~]$ ping www.newdns.lab
PING www.newdns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.024 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.089 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.074 ms
...
```

## **Настройка split-dns** ##

Создадим Views на master DNS (ns01) исходя из требований:

```
клиент1 - видит обе зоны, но в зоне dns.lab только web1

клиент2 видит только dns.lab
```

Приведём файлы 'master-named.conf' и 'slave-named.conf' к виду, в котором они сейчас приложены к ДЗ. Добавим файл зоны 'named.dns-cli1.lab', в котором опишем только те записи, которые может видеть client1.

Перезапустим сервис 'named' на обоих серверах. И проверим разрешение имён с клиентских машин:

Client1 разрешение имён через ns01:

```
[vagrant@client1 ~]$ dig @192.168.50.10  web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64429
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.
....
```

```
[vagrant@client1 ~]$ dig @192.168.50.10  web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 19647
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; AUTHORITY SECTION:
dns.lab.		600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Dec 07 13:20:50 UTC 2021
;; MSG SIZE  rcvd: 87
```

```
[vagrant@client1 ~]$ dig @192.168.50.10  www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12262
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.15
www.newdns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
newdns.lab.		3600	IN	NS	ns01.newdns.lab.
newdns.lab.		3600	IN	NS	ns02.newdns.lab.

;; ADDITIONAL SECTION:
ns01.newdns.lab.	3600	IN	A	192.168.50.10
ns02.newdns.lab.	3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Dec 07 13:21:25 UTC 2021
;; MSG SIZE  rcvd: 145
```

Client1 разрешение имён через ns02:

```
[vagrant@client1 ~]$ dig @192.168.50.11  web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 6585
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.
....
```

```
[vagrant@client1 ~]$ dig @192.168.50.11  web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 31547
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; AUTHORITY SECTION:
dns.lab.		600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 1 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Tue Dec 07 13:40:22 UTC 2021
;; MSG SIZE  rcvd: 87
```

```
[vagrant@client1 ~]$ dig @192.168.50.11  www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49089
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.15
www.newdns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
newdns.lab.		3600	IN	NS	ns01.newdns.lab.
newdns.lab.		3600	IN	NS	ns02.newdns.lab.
....
```

Client2 разрешение имён через ns01:

```
[vagrant@client2 ~]$ dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48702
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.
....
```

```
[vagrant@client2 ~]$ dig @192.168.50.10 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 56481
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.
....
```

```
[vagrant@client2 ~]$ dig @192.168.50.10 www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 52843
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; AUTHORITY SECTION:
.			10800	IN	SOA	a.root-servers.net. nstld.verisign-grs.com. 2021120700 1800 900 604800 86400

;; Query time: 218 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Dec 07 13:25:24 UTC 2021
;; MSG SIZE  rcvd: 118
```

Client2 разрешение имён через ns02:

```
[vagrant@client2 ~]$ dig @192.168.50.11 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 28076
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.
....
```

```
[vagrant@client2 ~]$ dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 826
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.
....
```

```
[vagrant@client2 ~]$ dig @192.168.50.11 www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.11 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 52840
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	A

;; AUTHORITY SECTION:
.			10800	IN	SOA	a.root-servers.net. nstld.verisign-grs.com. 2021120700 1800 900 604800 86400

;; Query time: 210 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Tue Dec 07 13:46:51 UTC 2021
;; MSG SIZE  rcvd: 118
```

На slave DNS (ns02) потребовалось добавить ещё один IP адрес на интерфейс eth1. С этого IP идёт обновление зоны домена dns.lab, которую получает client2. Так же на сервере ns02 потребовалось изменить путь для хранения файлов зон. Каталог '/etc/named/' заменён на '/var/named/slaves'. Иначе selinux не разрешал создавать файлы зон.