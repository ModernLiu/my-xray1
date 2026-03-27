#!/bin/bash

# ===== Reality 菜单版（稳定可用）=====

CONFIG="/usr/local/etc/xray/config.json"
SERVICE="/etc/systemd/system/xray.service"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

[ "$(id -u)" != "0" ] && echo -e "${RED}请用 root 运行${PLAIN}" && exit 1

install_xray() {
echo -e "${GREEN}安装 Xray 核心...${PLAIN}"

cd /tmp
rm -f Xray-linux-64.zip

wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o Xray-linux-64.zip >/dev/null

install -m 755 xray /usr/local/bin/xray
mkdir -p /usr/local/etc/xray

echo -e "${GREEN}Xray 安装完成${PLAIN}"
}

create_service() {
cat > $SERVICE <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray run -config $CONFIG
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray
}

gen_config() {

UUID=$(cat /proc/sys/kernel/random/uuid)

KEY=$(xray x25519)
PRIVATE=$(echo "$KEY" | grep Private | awk '{print $3}')
PUBLIC=$(echo "$KEY" | grep Public | awk '{print $3}')

read -p "输入端口(默认443): " PORT
PORT=${PORT:-443}

read -p "输入伪装域名(默认cloudflare): " DOMAIN
DOMAIN=${DOMAIN:-www.cloudflare.com}

cat > $CONFIG <<EOF
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
"dest":"${DOMAIN}:443",
"serverNames":["$DOMAIN"],
"privateKey":"$PRIVATE",
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

echo ""
echo -e "${GREEN}====== 配置完成 ======${PLAIN}"
echo "IP: $IP"
echo "端口: $PORT"
echo "UUID: $UUID"
echo "公钥: $PUBLIC"
echo ""
echo "节点："
echo "vless://${UUID}@${IP}:${PORT}?security=reality&sni=${DOMAIN}&fp=chrome&pbk=${PUBLIC}&type=tcp"
}

change_port() {
read -p "新端口: " PORT
sed -i "s/\"port\":.*/\"port\":$PORT,/" $CONFIG
systemctl restart xray
echo -e "${GREEN}端口已修改${PLAIN}"
}

change_domain() {
read -p "新域名: " DOMAIN
sed -i "s#dest.*#dest\":\"${DOMAIN}:443\",#g" $CONFIG
sed -i "s#serverNames.*#serverNames\":[\"$DOMAIN\"],#g" $CONFIG
systemctl restart xray
echo -e "${GREEN}域名已修改${PLAIN}"
}

add_user() {
UUID=$(cat /proc/sys/kernel/random/uuid)
sed -i "s#clients\":\[#{\"id\":\"$UUID\"},#g" $CONFIG
systemctl restart xray
echo "新UUID: $UUID"
}

status_xray() {
systemctl status xray --no-pager
}

menu() {
clear
echo -e "${YELLOW}===== Reality 菜单 =====${PLAIN}"
echo "1. 安装 Xray"
echo "2. 初始化配置"
echo "3. 修改端口"
echo "4. 修改伪装域名"
echo "5. 新增用户"
echo "6. 查看状态"
echo "0. 退出"
echo "======================="
read -p "选择: " num

case "$num" in
1) install_xray; create_service ;;
2) gen_config ;;
3) change_port ;;
4) change_domain ;;
5) add_user ;;
6) status_xray ;;
0) exit ;;
*) echo "错误";;
esac
}

while true; do
menu
read -p "回车继续..."
done
    esac
done

