#!/bin/bash

# Check user permissions and get server IP
SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
if [ $USER != 'root' ]; then
	UNAME=$USER
	echo -e "\n### User is not root. Continue..."
else
	echo -e "\n### ROOT USER DETECTED. EXIT and connect with ssh ${UNAME}@${SERVER_PUB_IP}"
fi

#########################
# Installation parameters
#########################
# Shadowsocks Rust
SSR_VERSION="1.15.4" # The latest one can be viewed here https://github.com/shadowsocks/shadowsocks-rust/releases
SSR_PORT=12345 # Сan be kept, or changed to any available port
SSR_PASSWORD="iddqd" # Set your password

# V2ray
V2RAY_VERSION="1.3.1" # The latest one can be viewed here https://github.com/shadowsocks/v2ray-plugin/releases
V2RAY_PORT=88 # Сan be kept, or changed to any available port
V2RAY_HOST="vk.com" # Set any host

# Domains settings
AGH_DOMAIN="" # Domain name for DNS Over HTTPS


#########################
# Shadowsocks Rust
#########################
function ssr() {
	echo "Installing Shadowsocks Rust"
	sudo wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v$SSR_VERSION/shadowsocks-v$SSR_VERSION.x86_64-unknown-linux-gnu.tar.xz
	sudo tar -xvf shadowsocks-v$SSR_VERSION.x86_64-unknown-linux-gnu.tar.xz
	sudo cp ssserver /usr/local/bin
	sudo mkdir /etc/shadowsocks/
	
	# Create ssr config
	echo "
{
\"server\": \"0.0.0.0\",
\"server_port\": ${SSR_PORT},
\"password\": \"${SSR_PASSWORD}\",
\"timeout\": 120,
\"method\": \"chacha20-ietf-poly1305\",
\"ipv6_first\": false,
\"nameserver\": \"127.0.0.1\",
\"mode\": \"tcp_only\"
}" | sudo tee /etc/shadowsocks/shadowsocks-rust.json

	# Create ssr service
	echo '
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
	WantedBy=multi-user.target' | sudo tee /etc/systemd/system/shadowsocks-rust.service

	# sysctl custom settings
	echo "
	# max open files
	fs.file-max = 51200
	# max read buffer
	net.core.rmem_max = 67108864
	# max write buffer
	net.core.wmem_max = 67108864
	# default read buffer
	net.core.rmem_default = 65536
	# default write buffer
	net.core.wmem_default = 65536
	# max processor input queue
	net.core.netdev_max_backlog = 4096
	# max backlog
	net.core.somaxconn = 4096

	# resist SYN flood attacks
	net.ipv4.tcp_syncookies = 1
	# reuse timewait sockets when safe
	net.ipv4.tcp_tw_reuse = 1
	# turn off fast timewait sockets recycling
	net.ipv4.tcp_tw_recycle = 0
	# short FIN timeout
	net.ipv4.tcp_fin_timeout = 30
	# short keepalive time
	net.ipv4.tcp_keepalive_time = 1200
	# outbound port range
	net.ipv4.ip_local_port_range = 10000 65000
	# max SYN backlog
	net.ipv4.tcp_max_syn_backlog = 4096
	# max timewait sockets held by system simultaneously
	net.ipv4.tcp_max_tw_buckets = 5000
	# turn on TCP Fast Open on both client and server side
	net.ipv4.tcp_fastopen = 3
	# TCP receive buffer
	net.ipv4.tcp_rmem = 4096 87380 67108864
	# TCP write buffer
	net.ipv4.tcp_wmem = 4096 65536 67108864
	# turn on path MTU discovery
	net.ipv4.tcp_mtu_probing = 1

	# for high-latency network
	net.ipv4.tcp_congestion_control = hybla

	# for low-latency network, use cubic instead
	# net.ipv4.tcp_congestion_control = cubic
	" | sudo tee /etc/sysctl.d/ssr.conf

	sudo systemctl enable shadowsocks-rust
	sudo systemctl start shadowsocks-rust
	sudo systemctl status shadowsocks-rust

	sudo sysctl -p

	cd ~/
	sudo rm shadowsocks-v$SSR_VERSION.x86_64-unknown-linux-gnu.tar.xz
	sudo rm -rf shadowsocks*
}

#########################
# V2RAY
#########################
function v2ray() {
	echo "Installing V2Ray"
	wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v$V2RAY_VERSION/v2ray-plugin-linux-amd64-v$V2RAY_VERSION.tar.gz
	tar -xvf v2ray-plugin-linux-amd64-v$V2RAY_VERSION.tar.gz
	sudo mv v2ray-plugin_linux_amd64 /etc/shadowsocks/v2ray-plugin
	sudo setcap "cap_net_bind_service=+eip" /etc/shadowsocks/v2ray-plugin && chmod +x /etc/shadowsocks/v2ray-plugin
	echo "
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
	ExecStart=/etc/shadowsocks/v2ray-plugin -server -host ${V2RAY_HOST} -localAddr ${SERVER_PUB_IP} -localPort ${V2RAY_PORT} -remoteAddr 127.0.0.1 -remotePort ${SSR_PORT} -loglevel none
	[Install]
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/v2ray.service

	sudo systemctl enable v2ray && sudo systemctl restart v2ray 

	sudo rm v2ray-plugin-linux-amd64-v1.3.1.tar.gz
	sudo rm -rf v2ray*

}


#########################
# Adguard Home
#########################
function agh(){
	echo "Installing AdGuard Home"
	echo $SERVER_PUB_IP
	sudo snap install adguard-home
	echo "Continue in browser at http://${SERVER_PUB_IP}:3000"
	echo "ATTENTION!!!
	Change web port to 8080, and DNS to 53 (default).
	After first setup, press Enter for generating SSL certificates"
	read
	sudo service apache2 stop
	FULL_DOMAIN=${1}
	sudo certbot certonly --standalone --preferred-challenges http --agree-tos --register-unsafely-without-email -d "$FULL_DOMAIN"
	sudo service apache2 start
}


function remove_all(){
		sudo rm /usr/local/bin/ssserver shadowsocks* ss*
		sudo rm /etc/shadowsocks/shadowsocks-rust.json
		sudo service shadowsocks-rust stop
		sudo rm /etc/systemd/system/shadowsocks-rust.service
		sudo reboot
}

ssr
v2ray
agh