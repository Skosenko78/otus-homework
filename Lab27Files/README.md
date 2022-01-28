# **Введение** #

Цель данной лабораторной работы изучить инструменты для работы с СУБД MySQL. Настроить репликацию, научиться делать бекап.


## **Описание** ##

Стенд состоит из двух виртуальных машин master и slave с ОС Centos 7. Репликация и копирование файла бекапа будет осуществляться по интерфейсам eth1 виртуальных машин master (192.168.11.150) и slave (192.168.11.151). При запуске стенда устанавливается MySQL и копируются файлы конфигурации.

## **Подготовка к репликации** ##

Для подключения к MySQL найдём пароль root, который был сгенерирован при установке:

```
[vagrant@master ~]$ sudo cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
=n5HxMT:#-_2
```
После подключения требуется сменить пароль для начала работы с базами:

```
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.36-39-log
...
...
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.
mysql> ALTER USER USER() IDENTIFIED BY 'Pa$$w0rd';
Query OK, 0 rows affected (0.00 sec)

mysql>
```

Узнаем и изменим пароль пользователя root на slave.

```
[vagrant@slave ~]$ SQLRPWD=$(sudo cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}');mysql -uroot -p$SQLRPWD
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.36-39-log

...
...

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>  ALTER USER USER() IDENTIFIED BY 'Pa$$w0rd';
Query OK, 0 rows affected (0.01 sec)

mysql>
```

Для работы репликации атрибуты server_id на master и slave должны отличаться. Проверим атрибут server_id на обоих серверах. 

```
master
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)

slave
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.00 sec)
```

Проверим, включён ли GTID на обоих серверах

```
master
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.01 sec)

slave
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.01 sec)
```

Для загрузки дампа базы она должна существовать. Создадим базу bet на сервере master, загрузим в нее дамп и проверим, что в базе появились таблицы:

```
mysql> CREATE DATABASE bet;
Query OK, 1 row affected (0.00 sec)

[vagrant@master ~]$ mysql -uroot -p -D bet < /vagrant/bet.dmp

mysql> USE bet;

Database changed
mysql> SHOW tables;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)
```

Создадим пользователя для репликации и дадим ему права на выполнение репликации:

```
mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2022';
Query OK, 0 rows affected (0.02 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '!OtusLinux2022';
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
1 row in set (0.00 sec)
```

Выгружаем базу для последующего залива на slave и исключаем таблицы events_on_demand и v_same_event:

```
[vagrant@master ~]$  mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -p > master.sql
Enter password: 
Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events. 
[vagrant@master ~]$
```

Скопируем файл дампа на сервер slave:

```
[vagrant@master ~]$ scp master.sql vagrant@192.168.11.151:~/      
master.sql                     100%  969KB  28.2MB/s   00:00    
[vagrant@master ~]$
```

Ключи для работы команды scp у нас были скопированы при запуске стенда.

## **Настройка репликации на slave** ##


Заливаем дамп с сервера master:

```
mysql> SOURCE ~/master.sql
```

При загрузке дампа появилась ошибка:

```
ERROR 1840 (HY000): @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.
```

Проверяем, что появилась база bet, в которой 5 таблиц. Таблицы events_on_demand и v_same_event отсутствуют, как и планировалось по заданию.

```
mysql> SHOW databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| bet                |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
mysql> USE bet;
Database changed
mysql> SHOW tables;
+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
5 rows in set (0.00 sec)
```

Подключаем и запускаем репликацию на сервере slave:

```
mysql>  CHANGE MASTER TO MASTER_HOST = "192.168.11.150", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2022", MASTER_AUTO_POSITION = 1;
Query OK, 0 rows affected, 2 warnings (0.03 sec)

mysql> START SLAVE;
Query OK, 0 rows affected (0.01 sec)

mysql>  SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 119568
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 627
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: No
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 1007
                   Last_Error: Error 'Can't create database 'bet'; database exists' on query. Default database: 'bet'. Query: 'CREATE DATABASE bet'
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 414
              Relay_Log_Space: 119988
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 1007
               Last_SQL_Error: Error 'Can't create database 'bet'; database exists' on query. Default database: 'bet'. Query: 'CREATE DATABASE bet'
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 73a9ed1f-7f76-11ec-bea5-5254004d77d3
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: 
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 220127 15:52:07
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39
            Executed_Gtid_Set: 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1,
e38ad12f-7f6f-11ec-a941-5254004d77d3:1
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)

```

На сервере master:

```
mysql> show master status\G
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 119568
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39
1 row in set (0.00 sec)
```

Ошибки репликации возникли из-за ошибки, которая была при загрузке дампа:

```
ERROR 1840 (HY000): @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.
```

При импорте переменная GTID_PURGED не смогла принять значение переменной GTID_EXECUTED сервера master, поскольку переменная GTID_EXECUTED сервера slave не была пустой. Попробуем исправить эту ошибку. Значение переменной на сервере master:

```
mysql> show global variables like 'GTID_EXECUTED';
+---------------+-------------------------------------------+
| Variable_name | Value                                     |
+---------------+-------------------------------------------+
| gtid_executed | 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39 |
+---------------+-------------------------------------------+
1 row in set (0.00 sec)
```

Данное значение должно быть в переменной GTID_PURGED сервера slave, поскольку все транзакции, указанные в переменной GTID_EXECUTED (транзакции, которые находятся в binary log), мы получили дампом. Установим значение переменной GTID_PURGED на сервере slave вручную:

```
mysql> RESET MASTER;
Query OK, 0 rows affected (0.01 sec)

mysql> show global variables like 'gtid_purged';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_purged   |       |
+---------------+-------+
1 row in set (0.01 sec)

mysql> show global variables like 'gtid_executed';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_executed |       |
+---------------+-------+
1 row in set (0.00 sec)

mysql> SET GLOBAL GTID_PURGED="73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39";                     
Query OK, 0 rows affected (0.00 sec)

mysql> start slave;
Query OK, 0 rows affected (0.01 sec)

mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 119568
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 119781
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 119568
              Relay_Log_Space: 119988
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 73a9ed1f-7f76-11ec-bea5-5254004d77d3
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39
            Executed_Gtid_Set: 73a9ed1f-7f76-11ec-bea5-5254004d77d3:1-39
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)
```

Теперь ошибок репликации нет. Проверим репликацию в действии. Добавим запись на сервере master:

```
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql>  INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.04 sec)

mysql>  SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```

Посмотрим записи в таблице bookmaker на сервере slave:

```
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```

На сервере slave появилась такая же запись. Репликация работает.
