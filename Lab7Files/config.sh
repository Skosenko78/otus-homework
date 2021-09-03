#!/bin/bash

# Установим инструменты для работы:
sudo yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils
# Скачиваем пакет с исходниками NGINX:
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
# Скачиваем дополнительный пакет:
wget https://www.openssl.org/source/latest.tar.gz
# Распакуем его в домашний каталог root:
sudo tar -xvf latest.tar.gz --directory=/root
# Создадим дерево каталогов для сборки пакета (в домашнем каталоге root):
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm


# Установка всех зависимостей, чтобы сборка пакета прошла без ошибок:
sudo yum-builddep -y /root/rpmbuild/SPECS/nginx.spec