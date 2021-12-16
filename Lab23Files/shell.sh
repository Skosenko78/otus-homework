cd /etc/openvpn/
# Инициализируем pki
/usr/share/easy-rsa/3.0.8/easyrsa init-pki

# Создадим сертификаты и ключи центра сертификации и RAS сервера
echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa build-ca nopass
echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req server nopass

# Подпишем сертификат server центром сертификации
echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req server server

# Сгенерируем Diffie-Hellman параметры
/usr/share/easy-rsa/3.0.8/easyrsa gen-dh
openvpn --genkey --secret ta.key

# Генерируем и подписываем сертификат для клиента.
echo 'client' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req client nopass
echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req client client

# Зададим параметр iroute для клиента
echo 'iroute 192.168.33.0 255.255.255.0' > /etc/openvpn/client/client
