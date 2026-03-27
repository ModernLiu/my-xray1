#!/bin/bash

# ==================================================
# Xray Reality PRO 管理腳本（防封加強版）
# 多端口 + 偽裝池 + 多用戶 + 菜單
# ==================================================

CONFIG="/usr/local/etc/xray/config.json"
DOMAIN_POOL=(
"www.cloudflare.com"
"www.microsoft.com"
"www.apple.com"
"www.amazon.com"
"www.google.com"
"www.youtube.com"
)

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

[ "$(id -u)" != "0" ] && echo -e "${RED}請用 root${PLAIN}" && exit 1

install_base() {
apt update -y || yum update -y
apt install -y jq curl openssl || yum install -y jq curl openssl
}

install_xray() {
echo -e "${GREEN}安裝 Xray${PLAIN}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

gen_keys() {
KEY=$(xray x25519)
PRI=$(echo "$KEY" | head -n1 | awk '{print $3}')
PUB=$(echo "$KEY" | tail -n1 | awk '{print $3}')
}

random_domain() {
echo ${DOMAIN_POOL[$RANDOM % ${#DOMAIN_POOL[@]}]}
}

add_node() {
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=$(shuf -i 20000-60000 -n 1)
DOMAIN=$(random_domain)
gen_keys

TMP=$(mktemp)

if [ ! -f "$CONFIG" ]; then
cat > $CONFIG <<EOF
{"inbounds":[],"outbounds":[{"protocol":"freedom"}]}
EOF
fi

jq ".inbounds += [{
  \"port\":$PORT,
  \"protocol\":\"vless\",
  \"settings\":{\"clients\":[{\"id\":\"$UUID\",\"flow\":\"xtls-rprx-vision\"}],\"decryption\":\"none\"},
  \"streamSettings\":{
    \"network\":\"tcp\",
    \"security\":\"reality\",
    \"realitySettings\":{
      \"dest\":\"${DOMAIN}:443\",
      \"serverNames\":[\"${DOMAIN}\"],
      \"privateKey\":\"$PRI\",
      \"shortIds\":[\"\"]
}}}]" $CONFIG > $TMP && mv $TMP $CONFIG

systemctl restart xray

IP=$(curl -s ifconfig.me)

echo -e "${GREEN}新增節點成功${PLAIN}"
echo "IP: $IP"
echo "PORT: $PORT"
echo "UUID: $UUID"
echo "SNI: $DOMAIN"
echo "PBK: $PUB"
echo ""
echo "vless://${UUID}@${IP}:${PORT}?security=reality&sni=${DOMAIN}&fp=chrome&pbk=${PUB}&type=tcp&flow=xtls-rprx-vision"
}

list_nodes() {
jq '.inbounds[].port' $CONFIG
}

del_node() {
read -p "輸入端口刪除: " PORT
jq "del(.inbounds[] | select(.port==$PORT))" $CONFIG > tmp && mv tmp $CONFIG
systemctl restart xray
echo -e "${GREEN}刪除完成${PLAIN}"
}

change_node() {
read -p "端口: " PORT
read -p "新偽裝域名: " DOMAIN

jq "(.inbounds[] | select(.port==$PORT) | .streamSettings.realitySettings.serverNames)=[\"$DOMAIN\"] |
(.inbounds[] | select(.port==$PORT) | .streamSettings.realitySettings.dest)=\"${DOMAIN}:443\"" \
$CONFIG > tmp && mv tmp $CONFIG

systemctl restart xray
echo -e "${GREEN}修改完成${PLAIN}"
}

add_user() {
read -p "端口: " PORT
UUID=$(cat /proc/sys/kernel/random/uuid)

jq "(.inbounds[] | select(.port==$PORT) | .settings.clients) += [{\"id\":\"$UUID\",\"flow\":\"xtls-rprx-vision\"}]" \
$CONFIG > tmp && mv tmp $CONFIG

systemctl restart xray
echo "UUID: $UUID"
}

bbr_on() {
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo -e "${GREEN}BBR 開啟${PLAIN}"
}

menu() {
clear
echo -e "${YELLOW}===== Reality PRO 管理 =====${PLAIN}"
echo "1. 安裝基礎環境"
echo "2. 安裝 Xray"
echo "3. 新增節點（自動偽裝）"
echo "4. 查看節點"
echo "5. 刪除節點"
echo "6. 修改節點偽裝"
echo "7. 新增用戶"
echo "8. 開啟 BBR"
echo "0. 退出"
echo "==========================="
read -p "選擇: " num

case "$num" in
1) install_base ;;
2) install_xray ;;
3) add_node ;;
4) list_nodes ;;
5) del_node ;;
6) change_node ;;
7) add_user ;;
8) bbr_on ;;
0) exit ;;
*) echo "錯誤";;
esac
}

while true; do
menu
read -p "Enter 繼續..."
done
    esac
done

