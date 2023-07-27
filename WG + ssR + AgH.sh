


	### ссылки на инструкции в самом низу

apt install sudo
sudo apt install -y ufw mc curl wget unzip zsh git certbot dnsutils nano htop net-tools 

### sudo apt -qq install -y ufw mc curl wget unzip zsh git mariadb-server mariadb-client python3-pip python3-venv certbot lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 dnsutils

### apt install -y wireguard apache2

apt update && apt upgrade -y



	### сертификат https

echo -e "\n### Creating SSL certificates..."
echo "Enter your domain name e.g. (example.com):"
read DOMAIN

m00vie.ru

echo "Enter subdomain for DoH e.g doh if you want doh.example.com:"
read SUBDOMAIN

dns

sudo certbot certonly --standalone --preferred-challenges http --agree-tos --register-unsafely-without-email -d $DOMAIN
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --register-unsafely-without-email -d $SUBDOMAIN.$DOMAIN

ОБНОВЛЕНИЕ СЕРТИФИКАТА:

certbot renew


###	сертификаты тут:
###	Your certificate and chain have been saved at:
		/etc/letsencrypt/live/m00vie.ru/fullchain.pem
	Your key file has been saved at:
		/etc/letsencrypt/live/m00vie.ru/privkey.pem
	Your certificate and chain have been saved at:
		/etc/letsencrypt/live/dns.m00vie.ru/fullchain.pem
	Your key file has been saved 
		/etc/letsencrypt/live/dns.m00vie.ru/privkey.pem

###	врененно:
		/etc/letsencrypt/live/m00.fvds.ru-0002/fullchain.pem
		/etc/letsencrypt/live/m00.fvds.ru-0002/privkey.pem




	### WireGuard

curl -L https://install.pivpn.io | bash

дописать в конфиг wg0.conf после блока Intrface:
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

pivpn add

	### ssR

cd /tmp
# проверить версию в браузере https://github.com/shadowsocks/shadowsocks-rust/releases/

sudo wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.15.1/shadowsocks-v1.15.1.aarch64-unknown-linux-gnu.tar.xz
sudo tar -xf shadowsocks-v1.15.1.aarch64-unknown-linux-gnu.tar.xz
sudo cp ssserver /usr/local/bin
sudo mkdir /etc/shadowsocks/
sudo nano /etc/shadowsocks/shadowsocks-rust.json

{
"server": "0.0.0.0",
"server_port": 12345,
"password": "iddqd",
"timeout": 120,
"method": "chacha20-ietf-poly1305",
"no_delay": true,
"fast_open": true,
"reuse_port": true,
"workers": 1,
"ipv6_first": false,
"nameserver": "127.0.0.1",
"mode": "tcp_only"
}

ctrl+o, Enter, ctrl+x

sudo nano /etc/systemd/system/shadowsocks-rust.service

[Unit]
Description=shadowsocks-rust service
After=network.target
[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/shadowsocks-rust.json
ExecStop=/usr/bin/killall ssserver
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=ssserver
User=nobody
Group=nogroup
[Install]
WantedBy=multi-user.target

ctrl+o, Enter, ctrl+x

sudo nano /etc/sysctl.conf

fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla

ctrl+o, Enter, ctrl+x.

sudo sysctl -p
sudo sysctl net.ipv4.tcp_available_congestion_control

Если в ответ получаем что-то типа этого: net.ipv4.tcp_available_congestion_control = reno cubic bbr hybla, значит всё настроено правильно.

sudo systemctl enable shadowsocks-rust
sudo systemctl start shadowsocks-rust
sudo systemctl status shadowsocks-rust

rm shadowsocks-v1.15.1.aarch64-unknown-linux-gnu.tar.xz

	### v2ray

# проверить версию в браузере https://github.com/shadowsocks/v2ray-plugin/releases
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.1/v2ray-plugin-linux-amd64-v1.3.1.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.1.tar.gz
mv v2ray-plugin_linux_amd64 /etc/shadowsocks/v2ray-plugin
setcap "cap_net_bind_service=+eip" /etc/shadowsocks/v2ray-plugin && chmod +x /etc/shadowsocks/v2ray-plugin
nano /etc/systemd/system/ss-v2ray-88.service

[Unit]
Description=v2ray standalone server service
Documentation=man:shadowsocks-rust(8)
After=network.target
[Service]
Type=simple
User=nobody
Group=nogroup
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
LimitNOFILE=51200
ExecStart=/etc/shadowsocks/v2ray-plugin -server -host www.vk.com -localAddr 188.120.237.98 -localPort 88 -remoteAddr 127.0.0.1 -remotePort 12345 -loglevel none
[Install]
WantedBy=multi-user.target

ctrl+o, Enter, ctrl+x.

systemctl enable ss-v2ray-88 && systemctl restart ss-v2ray-88 

rm v2ray-plugin-linux-amd64-v1.3.1.tar.gz


	### AdGuard Home
	### ставить через snap проще

snap install adguard-home

http://188.120.237.98:3000	# сервер выбрать ТОЛЬКО 127.0.0.1
nano /var/snap/adguard-home/3717/AdGuardHome.yaml
добавить последнюю строчку (или другую, в зависимости от настроек wg):
dns:
  bind_hosts:
  - 127.0.0.1
  - 10.6.0.1



### cd /
### wget https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz
### tar xvf AdGuardHome_linux_amd64.tar.gz
### cd AdGuardHome
### pwd
### systemctl disable systemd-resolved
### sudo ./AdGuardHome -s install
### cd /
### rm AdGuardHome_linux_amd64.tar.gz

	### mkdir /etc/systemd/resolved.conf.d/
	### nano /etc/systemd/resolved.conf.d/adguardhome.conf

	[Resolve]
	DNS=127.0.0.1
	DNSStubListener=no

	ctrl+o, Enter, ctrl+x.

	### sudo mv /etc/resolv.conf /etc/resolv.conf.backup
	### sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
	### systemctl reload-or-restart systemd-resolved






	### Ссылки

wg:
https://pivpn.io
https://youtu.be/XvbY-xY5dWY

ssR:
https://4pda.to/forum/index.php?showtopic=744431&st=3060#entry113691884

v2ray
https://4pda.to/forum/index.php?showtopic=744431&st=1580#entry96860833

AdGuard Home
https://akmalov.com/blog/adguard-home/?ysclid=l1dquhwkj5
https://github.com/AdguardTeam/AdGuardHome/wiki/VPS
https://github.com/AdguardTeam/AdGuardHome/wiki/FAQ#why-am-i-getting-bind-address-already-in-use-error-when-trying-to-install-on-ubuntu

