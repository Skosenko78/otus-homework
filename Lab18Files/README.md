# **Введение**

Цель данной лабораторной работы научиться настроивать сетевой интерфейс, менять IP адрес, подсеть, прописывать маршруты.

## Описание

Стенд состоит из семи серверов:
  - inetRouter
  - centralRouter
  - centralServer
  - office1Router
  - office1Server
  - office2Router
  - office2Server

## Теоретическая часть

1. Найти свободные подсети:

```
192.168.0.16/28 broadcast 192.168.0.31 available hosts 14
192.168.0.48/28 broadcast 192.168.0.63 available hosts 14
192.168.0.128/26 broadcast 192.168.0.191 available hosts 62
192.168.0.192/26 broadcast 192.168.0.255 available hosts 62
```

2. Указать broadcast адрес в каждой подсети и количество узлов:

Office 1
```
192.168.2.0/26 broadcast 192.168.2.63 available hosts 62
192.168.2.64/26 broadcast 192.168.2.127 available hosts 62
192.168.2.128/26 broadcast 192.168.2.191 available hosts 62
192.168.2.192/26 broadcast 192.168.2.255 available hosts 62
```

Office 2
```
192.168.1.0/25 broadcast 192.168.1.127 available hosts 126
192.168.1.128/26 broadcast 192.168.1.191 available hosts 62
192.168.1.192/26 broadcast 192.168.1.255 available hosts 62
```

Central
```
192.168.0.0/28 broadcast 192.168.0.15 available hosts 14
192.168.0.32/26 broadcast 192.168.0.47 available hosts 14
192.168.0.64/26 broadcast 192.168.0.127 available hosts 62
```

3. Ошибок при разбиении не обнаружил.

## Практическая часть

Офисы соединены в сеть согласно схеме, роутинг настроен. Доступ в сеть интернет осуществляется через inetRouter. Сервера обмениваются пакетами друг с другом.