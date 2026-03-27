#!/bin/bash

set -e

echo "=== Reality 安装脚本（稳定版）==="

# 检查 root
[ "$(id -u)" != "0" ] && echo "请用 root 运行" && exit 1

# 安装基础工具
if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y curl wget unzip openssl
else
    yum install -y curl wget unzip openssl
fi

# 下载 Xray（不用官方脚本，避免失败）
echo "下载 Xray..."
cd /tmp
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip

unzip -o Xray-linux-64.zip
install -m 755 xray /usr/local/bin/xray

mkdir -p /usr/local/etc/xray

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成密钥
KEY=$(xray x25519)
PRIVATE=$(echo "$KEY" | grep Private | awk '{print $3}')
PUBLIC=$(echo "$KEY" | grep Public | awk '{print $3}')

PORT=443

# 写配置
cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds":[
    {
      "port":$PORT,
      "protocol":"vless",
      "settings":{
        "clients":[{"id":"$UUID"}],
        "decryption":"none"
      },
      "streamSettings":{
        "network":"tcp",
        "security":"reality",
        "realitySettings":{
          "dest":"www.cloudflare.com:443",
          "serverNames":["www.cloudflare.com"],
          "privateKey":"$PRIVATE",
          "shortIds":[""]
        }
      }
    }
  ],
  "outbounds":[{"protocol":"freedom"}]
}
EOF

# systemd
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray
After=network.target

[Service]
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

IP=$(curl -s ifconfig.me)

echo ""
echo "====== 成功 ======"
echo "IP: $IP"
echo "端口: $PORT"
echo "UUID: $UUID"
echo "公钥: $PUBLIC"
echo ""
echo "节点："
echo "vless://${UUID}@${IP}:${PORT}?security=reality&sni=www.cloudflare.com&fp=chrome&pbk=${PUBLIC}&type=tcp"
done
    esac
done

