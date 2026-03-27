#!/bin/bash

# ==================================================
# Xray Reality 管理腳本（進階版 / 多用戶 / 菜單）
# ==================================================

CONFIG="/usr/local/etc/xray/config.json"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

# root 檢查
[ "$(id -u)" != "0" ] && echo -e "${RED}請用 root 執行${PLAIN}" && exit 1

install_xray() {
    echo -e "${GREEN}安裝 Xray...${PLAIN}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

gen_base_config() {
UUID=$(cat /proc/sys/kernel/random/uuid)
KEY=$(xray x25519)
PRI=$(echo "$KEY" | head -n1 | awk '{print $3}')
PUB=$(echo "$KEY" | tail -n1 | awk '{print $3}')
PORT=$(shuf -i 20000-50000 -n 1)

cat > $CONFIG <<EOF
{
  "inbounds":[
    {
      "port":$PORT,
      "protocol":"vless",
      "settings":{
        "clients":[
          {
            "id":"$UUID",
            "flow":"xtls-rprx-vision"
          }
        ],
        "decryption":"none"
      },
      "streamSettings":{
        "network":"tcp",
        "security":"reality",
        "realitySettings":{
          "dest":"www.cloudflare.com:443",
          "serverNames":["www.cloudflare.com"],
          "privateKey":"$PRI",
          "shortIds":[""]
        }
      }
    }
  ],
  "outbounds":[{"protocol":"freedom"}]
}
EOF

systemctl restart xray

IP=$(curl -s ifconfig.me)

echo -e "${GREEN}完成${PLAIN}"
echo "IP: $IP"
echo "PORT: $PORT"
echo "UUID: $UUID"
echo "PublicKey: $PUB"

echo ""
echo "vless://${UUID}@${IP}:${PORT}?security=reality&sni=www.cloudflare.com&fp=chrome&pbk=${PUB}&type=tcp&flow=xtls-rprx-vision"
}

add_user() {
UUID=$(cat /proc/sys/kernel/random/uuid)

jq ".inbounds[0].settings.clients += [{\"id\":\"$UUID\",\"flow\":\"xtls-rprx-vision\"}]" $CONFIG > tmp.json && mv tmp.json $CONFIG

systemctl restart xray

echo -e "${GREEN}新增用戶成功${PLAIN}"
echo "UUID: $UUID"
}

del_user() {
read -p "輸入 UUID: " UUID

jq "del(.inbounds[0].settings.clients[] | select(.id==\"$UUID\"))" $CONFIG > tmp.json && mv tmp.json $CONFIG

systemctl restart xray
echo -e "${GREEN}刪除完成${PLAIN}"
}

list_user() {
jq '.inbounds[0].settings.clients' $CONFIG
}

change_port() {
read -p "新端口: " PORT
jq ".inbounds[0].port=$PORT" $CONFIG > tmp.json && mv tmp.json $CONFIG
systemctl restart xray
echo -e "${GREEN}修改完成${PLAIN}"
}

change_domain() {
read -p "新偽裝域名: " DOMAIN
jq ".inbounds[0].streamSettings.realitySettings.serverNames=[\"$DOMAIN\"] | .inbounds[0].streamSettings.realitySettings.dest=\"${DOMAIN}:443\"" $CONFIG > tmp.json && mv tmp.json $CONFIG
systemctl restart xray
echo -e "${GREEN}修改完成${PLAIN}"
}

bbr_on() {
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo -e "${GREEN}BBR 開啟完成${PLAIN}"
}

menu() {
clear
echo -e "${YELLOW}===== Reality 管理面板 =====${PLAIN}"
echo "1. 安裝 Xray"
echo "2. 生成 Reality 節點"
echo "3. 新增用戶"
echo "4. 刪除用戶"
echo "5. 查看用戶"
echo "6. 修改端口"
echo "7. 修改偽裝域名"
echo "8. 開啟 BBR"
echo "0. 退出"
echo "================================"
read -p "請選擇: " num

case "$num" in
1) install_xray ;;
2) gen_base_config ;;
3) add_user ;;
4) del_user ;;
5) list_user ;;
6) change_port ;;
7) change_domain ;;
8) bbr_on ;;
0) exit ;;
*) echo "錯誤";;
esac
}

while true; do
menu
read -p "按 Enter 繼續..."
done1 ;;
    esac
done
