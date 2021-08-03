# **Введение**

Цель лабораторной работы познакомиться с такими инструментами, как `VirtualBox`, `Vagrant`, `Packer` и получить базовые навыки работы с системой контроля версий (`Github`). Получить навыки создания кастомных образов виртуальных машин и основам их распространения через репозиторий `Vagrant Cloud`. Так же получить навыки по обновлению ядра системы из репозитория.

В качестве хостовой системы используется ноутбук с установленной ОС `Ubuntu 20.04/Focal`

Заводим аккаунты:

- **GitHub** - https://github.com/
- **Vagrant Cloud** - https://app.vagrantup.com


---
# **Установка ПО**

### **VirualBox**
В консоли выполняем 

```
apt-get update 
apt-get install virtualbox
```

### **Vagrant**
Переходим на https://www.vagrantup.com/downloads.html выбираем соответствующую версию. Копируем команды и в консоли выполняем:

```
url -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vagrant
```

### **Packer**
Переходим на https://www.packer.io/downloads.html выбираем соответствующую версию. Ключи и репозиторий мы добавили в предыдущем шаге. Поэтому в консоли выполняем только:

```
sudo apt-get install packer
```

### **Git**
В консоли выполняем 

```
apt-get install git
```

---

# **Kernel update**

### **Клонирование и запуск**

Заходим через браузер в GitHub со своей учетной записью и выполняем `fork` данного репозитория: https://github.com/dmitry-lyutenko/manual_kernel_update

После этого клонируем данный репозиторий к себе на рабочую машину. Для этого используем команду
```
git clone git@github.com:<user_name>/manual_kernel_update.git
```
В текущей директории появилась папка с именем  `manual_kernel_update`.

Для удобства копируем файлы из директории `manual_kernel_update` в `Lab1Files`.
Создаём пустой репозиторий Git, добавляем содержимое нужных файлов в индекс, подключаем удалённый репозиторий, копируем содержимое локального репозитория в удалённый: 

```
git init
git add README.md
git add Lab1Files/README.md
git add Lab1Files/Vagrantfile
git config --global user.email "kosenko_sergei@mail.ru"
git config --global user.name "Sergey Kosenko"
git commit -m "First commit" 
git remote add origin https://github.com/Skosenko78/otus-homework.git
git push -u origin master
```

Запустим виртуальную машину и залогинимся:
```
vagrant up
...
==> kernel-update: Importing base box 'centos/7'...
...
==> kernel-update: Booting VM...
...
==> kernel-update: Setting hostname...

vagrant ssh
[vagrant@kernel-update ~]$ uname -r
3.10.0-1127.el7.x86_64
```
Теперь приступим к обновлению ядра.

### **kernel update**


Подключаем репозиторий, откуда возьмем необходимую версию ядра.
```
sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

Ставим последнее ядро:

```
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```

### **grub update**
После успешной установки нам необходимо сказать системе, что при загрузке нужно использовать новое ядро. 

Обновляем конфигурацию загрузчика:
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
Выбираем загрузку с новым ядром по-умолчанию:
```
sudo grub2-set-default 0
```

Перезагружаем виртуальную машину:
```
sudo reboot
```

После перезагрузки виртуальной машины заходим в нее и выполняем:

```
uname -r
```
Получаем:

```
vagrant@kernel-update ~]$ uname -r
5.13.7-1.el7.elrepo.x86_64
```

---

# **Packer**
Теперь необходимо создать свой образ системы, с уже установленым ядром 5й версии. Для этого воспользуемся ранее установленной утилитой `packer`. В директории `packer` есть все необходимые настройки и скрипты для создания необходимого образа системы.

### **packer provision config**
Описание настроеек виртуальной машины и исходных образов находится в файле `centos.json`


### **packer build**
Для создания образа системы переходим в директорию `packer` и выполняем команду:

```
packer build centos.json
```

Для продолжения создания образа потребовалось добавить команду:

```
packer fix centos.json > centosnew.json
```

И использовать новый файл описания:

```
packer build centosnew.json
```
Был скачан исходный iso-образ CentOS, установлен на виртуальную машину в автоматическом режиме, обновлено ядро и осуществлен экспорт в указанный нами файл. В текущей директории появился файл `centos-7.7.1908-kernel-5-x86_64-Minimal.box` - результат работы `packer`.

### **vagrant init (тестирование)**
Проведем тестирование созданного образа. Выполним его импорт в `vagrant`:

```
vagrant box add --name centos-7-5 centos-7.7.1908-kernel-5-x86_64-Minimal.box
```

Проверим его в списке имеющихся образов:

```
vagrant box list
centos-7-5 (virtualbox, 0)
centos/7   (virtualbox, 2004.01)
```

Проводим тестирование полученного образа. Для этого воспользуемся имеющимся Vagrantfile файлом.
Заменим значение `box_name` на имя импортированного образа. Соотвествующая строка примет вид:

```
:box_name => "centos-7-5",
```

Запускаеи виртуальную машину, подключаемся к ней и проверяем, что у нас в ней новое ядро:

```
vagrant up
...
vagrant ssh    
```

и внутри виртуальной машины:

```
[vagrant@kernel-update-packer ~]$ uname -r
5.3.1-1.el7.elrepo.x86_64
```

---
# **Vagrant cloud**

Копируем образ в Vagrant Cloud.
Логинимся в `vagrant cloud`
```
vagrant cloud auth login
Vagrant Cloud username or email: <user_email>
Password (will be hidden): 
Token description (Defaults to "Vagrant login from DS-WS"):
You are now logged in.
```
Публикуем полученный бокс:
```
vagrant cloud publish --release skosenko78/centos-7-5 1.0 virtualbox \
        centos-7.7.1908-kernel-5-x86_64-Minimal.box
```
Получаем сообщение:

```
Complete! Published skosenko78/centos-7-5
Box:              skosenko78/centos-7-5
Description:      
Private:          yes
Created:          2021-08-03T10:04:27.284Z
Updated:          2021-08-03T10:04:27.284Z
Current Version:  N/A
Versions:         1.0
Downloads:        0
```

В результате образ виртуальной машины создан и загружен в `vagrant cloud`.