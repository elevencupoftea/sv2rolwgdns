#!/bin/bash
# XTLS Reality install script
# Details: https://habr.com/ru/articles/731608/

XRAY_VERSION="1.8.4"
DOMAIN="dl.google.com"

wget https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/Xray-linux-64.zip
sudo mkdir /opt/xray
sudo unzip ./Xray-linux-64.zip -d /opt/xray
sudo chmod +x /opt/xray/xray

# Generate needs
XRAY_UUID=$(/opt/xray/xray uuid)
output=$(/opt/xray/xray x25519)
XRAY_PRIVATE=$(echo "$output" | awk '/Private key:/ {print $NF}')
XRAY_PUBLIC=$(echo "$output" | awk '/Public key:/ {print $NF}')
SHORT_ID=$(openssl rand -hex 8)
wget https://github.com/fumiyas/qrc/releases/download/v0.1.1/qrc_linux_amd64
chmod +x qrc_linux_amd64
sudo mv qrc_linux_amd64 /usr/bin/qrc

echo $XRAY_UUID
echo $XRAY_PRIVATE
echo $XRAY_PUBLIC
echo SHORT_ID

# Create config
echo "{
  \"log\": {
    \"loglevel\": \"info\"
  },
  \"routing\": {
    \"rules\": [],
    \"domainStrategy\": \"AsIs\"
  },
  \"inbounds\": [
    {
      \"port\": 443,
      \"protocol\": \"vless\",
      \"tag\": \"vless_tls\",
      \"settings\": {
        \"clients\": [
          {
            \"id\": \"${XRAY_UUID}\",
            \"email\": \"user1@myserver\",
            \"flow\": \"xtls-rprx-vision\"
          }
        ],
        \"decryption\": \"none\"
      },
      \"streamSettings\": {
        \"network\": \"tcp\",
        \"security\": \"reality\",
    \"realitySettings\": {
      \"show\": false,
      \"dest\": \"www.microsoft.com:443\",
      \"xver\": 0,
      \"serverNames\": [
        \"www.microsoft.com\"
      ],
      \"privateKey\": \"${XRAY_PRIVATE}\",
      \"minClientVer\": \"\",
      \"maxClientVer\": \"\",
      \"maxTimeDiff\": 0,
      \"shortIds\": [
        \"${SHORT_ID}\"
      ]
    }
      },
      \"sniffing\": {
        \"enabled\": true,
        \"destOverride\": [
          \"http\",
          \"tls\"
        ]
      }
    }
  ],
  \"outbounds\": [
    {
      \"protocol\": \"freedom\",
      \"tag\": \"direct\"
    },
    {
      \"protocol\": \"blackhole\",
      \"tag\": \"block\"
    }
  ]
}
" | sudo tee /opt/xray/config.json

# Create and start services
echo "[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/opt/xray/xray run -config /opt/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/xray.service
sudo systemctl enable xray
sudo systemctl restart xray

# Create client config
CLIENT_CONFIG=$(echo -e "vless://${XRAY_UUID}@80.76.42.199:443/?type=tcp&encryption=none&flow=xtls-rprx-vision&sni=${DOMAIN}&fp=chrome&security=reality&pbk=${XRAY_PUBLIC}&sid=${SHORT_ID}#vLESs")
echo $CLIENT_CONFIG
qrc $CLIENT_CONFIG