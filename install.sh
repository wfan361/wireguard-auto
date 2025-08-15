#!/bin/bash
set -e

CLIENT_NAME="vpn-client"
WG_PORT=51820
WG_INTERFACE="wg0"
DNS="1.1.1.1"

if [ "$(id -u)" -ne 0 ]; then
    echo "请用 root 运行此脚本"
    exit 1
fi

apt update
apt install -y wireguard qrencode curl

SERVER_IP=$(curl -4 ifconfig.me)

SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)
CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
CLIENT_PSK=$(wg genpsk)

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
[Interface]
PrivateKey = ${SERVER_PRIV_KEY}
Address = 10.0.0.1/24
ListenPort = ${WG_PORT}
SaveConfig = true

[Peer]
PublicKey = ${CLIENT_PUB_KEY}
PresharedKey = ${CLIENT_PSK}
AllowedIPs = 10.0.0.2/32
EOF

cat > /root/${CLIENT_NAME}.conf <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = 10.0.0.2/24
DNS = ${DNS}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${CLIENT_PSK}
Endpoint = ${SERVER_IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
EOF

systemctl enable wg-quick@${WG_INTERFACE}
systemctl start wg-quick@${WG_INTERFACE}

echo "=== 客户端配置二维码（手机可直接扫码） ==="
qrencode -t ansiutf8 < /root/${CLIENT_NAME}.conf
echo "=== 客户端配置文件路径：/root/${CLIENT_NAME}.conf ==="
