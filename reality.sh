#!/bin/bash

echo "🚀 开始安装 Xray Reality..."

# 安装 Xray
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh) install

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成密钥
KEY_PAIR=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | head -n1 | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | tail -n1 | awk '{print $3}')

# 随机端口（1-65535）
PORT=$((RANDOM % 65535 + 1))

echo "端口: $PORT"
echo "UUID: $UUID"

# 写入配置
cat > /usr/local/etc/xray/config.json <<EOF
{
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
          "dest": "www.cloudflare.com:443",
          "xver": 0,
          "serverNames": [
            "www.cloudflare.com"
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

# 启动服务
systemctl restart xray
systemctl enable xray

echo "================================"
echo "✅ 安装完成"
echo "地址: $(curl -s ifconfig.me)"
echo "端口: $PORT"
echo "UUID: $UUID"
echo "公钥: $PUBLIC_KEY"
echo "================================"
