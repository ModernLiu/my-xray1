#!/bin/bash

# ==================================================
# Xray Reality 一键安装脚本（纯净版 / 无广告 / 安全）
# ==================================================

set -e

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

CONFIG_PATH="/usr/local/etc/xray/config.json"

# 检查 root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}请用 root 身份运行${PLAIN}"
    exit 1
fi

echo -e "${GREEN}开始安装 Xray (官方版本)...${PLAIN}"

# 安装 Xray 官方
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 安装依赖
apt update -y || yum update -y
apt install -y openssl curl || yum install -y openssl curl

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成 Reality 密钥
KEY_PAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | head -n1 | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | tail -n1 | awk '{print $3}')

# 端口
PORT=$(shuf -i 20000-50000 -n 1)

# 伪装网站
DEST="www.cloudflare.com:443"
SERVER_NAME="www.cloudflare.com"

echo -e "${YELLOW}生成配置中...${PLAIN}"

mkdir -p /usr/local/etc/xray

cat > $CONFIG_PATH <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$DEST",
          "xver": 0,
          "serverNames": [
            "$SERVER_NAME"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            ""
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

echo -e "${GREEN}启动 Xray...${PLAIN}"

systemctl daemon-reexec
systemctl enable xray
systemctl restart xray

IP=$(curl -s ifconfig.me)

echo ""
echo -e "${GREEN}================ 安装完成 ================${PLAIN}"
echo -e "${GREEN}地址: ${IP}${PLAIN}"
echo -e "${GREEN}端口: ${PORT}${PLAIN}"
echo -e "${GREEN}UUID: ${UUID}${PLAIN}"
echo -e "${GREEN}公钥: ${PUBLIC_KEY}${PLAIN}"
echo -e "${GREEN}伪装域名: ${SERVER_NAME}${PLAIN}"
echo ""

echo -e "${YELLOW}VLESS 链接：${PLAIN}"
echo "vless://${UUID}@${IP}:${PORT}?encryption=none&security=reality&sni=${SERVER_NAME}&fp=chrome&pbk=${PUBLIC_KEY}&type=tcp&flow=xtls-rprx-vision#Reality"

echo ""
echo -e "${GREEN}=========================================${PLAIN}"
