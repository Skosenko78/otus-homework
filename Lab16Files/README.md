# **Введение**

Цель данной лабораторной работы понять как собирать логи, освоить принципы логирования с помощью rsyslog. На практике применить работу с сервисами auditd, journald, стек elk.

## Описание

Стенд состоит из трёх серверов.
- 'Web' с ОС Centos 8 и Nginx сервером. Является источником логов для центрального сервера и ELK
- 'Log' с ОС Centos 8. Центральный сервер для сбора логов
- 'wvds132865' с ОС Centos 8. Установлены Elasticsearch, Logstash и Kibana

Сервера 'Web' и 'Log' описаны в Vagrant файле и разворачиваются на локальной машине. 'wvds132865' расположен на ресурсах площадки Websa.

## Центральный лог сервер (Log)

Настройки для центрального лог сервера описаны в файле 'scustom.conf'. Файл копируется при запуске стенда в каталог '/etc/rsyslog.d/'. Служба rsyslog прослушивает tcp порт 10514 и раскладывает полученные логи от хоста 10.0.0.41 по файлам:
- /var/log/rsyslog/10.0.0.41/audit_log все логи от службы auditd
- /var/log/rsyslog/10.0.0.41/nginx_err_log все логи ошибок от сервиса Nginx
- /var/log/rsyslog/10.0.0.41/critical критичные логи с сервера Web

## Веб сервер (Web)

Настройки для службы rsyslog Web сервера описаны в файле 'ccustom.conf'. Файл так же копируется при запуске стенда в каталог '/etc/rsyslog.d/'. Демон auditd настраивается на запись событий связанных с файлами конфигурации Nginx и добавлет им ключ 'NGINX_CONFIG' для облегчения поиска в файле журнала. 
Служба rsyslog записывает события в соответствии со следующим описанием:
- событиям из файла audit.log присваивается метка 'tag_audit_log:', facility 'local6.' и копируются на центральный лог сервер 'Web' (10.0.0.42).
- событиям из файла /var/log/nginx/error.log присваивается метка  'tag_nginx_error:', facility 'local0. и так же копируются на центральный лог сервер 'Web' (10.0.0.42).
- события с уровнем важности 'crit' сохраняются в файл '/var/log/critical' и так же отправляются на центральный лог сервер 'Web' (10.0.0.42).
Также при запуске стенда копируется файл 'filebeat.yml', в котором указаны настройки для отправки всех логов Nginx в базу Elasticsearch.

## ELK сервер

Установку Elasticsearch начнём с установки Java:

```
yum install -y java-1.8.0-openjdk
```

Добавим репозиторий:

Файл '/etc/yum.repos.d/CentOS-Linux-Elastic.repo' с содержанием:

```
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

Установим базу Elasticsearch:

```
yum -y install elasticsearch
```

Проверим работу базы:

```
[adminroot@wvds132865 ~]$ curl -GET localhost:9200/_cat/health?v
epoch      timestamp cluster       status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1637758629 12:57:09  elasticsearch green           1         1      1   1    0    0        0             0                  -                100.0%
```

И посмотрим индексы в базе:

```
[adminroot@wvds132865 ~]$ curl -GET localhost:9200/_cat/indices?v
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases VnVH_g8YQ-mOiuMq21ylsg   1   0         66            0     64.6mb         64.6mb
```

Установим Kibana и Logstash:

```
yum install -y kibana
```

```
yum install -y logstash
```

Создадим 3 файла:

```
/etc/logstash/conf.d/01-beats-input.conf
input {
	beats {
	port => 5044
	}
}
```

```
/etc/logstash/conf.d/10-nginx-filter.conf
filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 geoip {
   source => "clientip"
   add_tag => [ "nginx-geoip" ]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}
```

```
/etc/logstash/conf.d/20-output.conf
output {
 elasticsearch {
   hosts => ["localhost:9200"]
   index => "weblogs-%{+YYYY.MM.dd}"
   document_type => "nginx_logs"
 }
}
```

Запустим сервисы.
Подключиться к Elasticsearch можно по адресу:

```
http://185.189.68.218:5601/
```