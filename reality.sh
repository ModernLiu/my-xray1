#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

install_base() {
    apt update && apt install wget curl tar openssl jq -y || yum install wget curl tar openssl jq -y
}

show_config() {
    if [[ ! -f /usr/local/etc/xray/config.json ]]; then
        echo -e "${red}未检测到配置文件，请先安装！${plain}"
        return
    fi
    local ip=$(curl -s ipv4.icanhazip.com)
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' /usr/local/etc/xray/config.json)
    local sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' /usr/local/etc/xray/config.json)
    local pbk=$(cat /usr/local/etc/xray/public_key.txt 2>/dev/null)
    echo -e "\n${green}配置信息：${plain}\nIP: $ip\nUUID: $uuid\nPublic Key: $pbk\nShortID: $sid\n"
    echo -e "${yellow}分享链接：${plain}"
    echo -e "vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_Node"
}

generate_config() {
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    mkdir -p /usr/local/etc/xray
    echo "$pub" > /usr/local/etc/xray/public_key.txt
    cat << EOF > /usr/local/etc/xray/config.json
{"log":{"loglevel":"warning"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"$uuid","flow":"xtls-rprx-vision"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"show":false,"dest":"www.lovelive-anime.jp:443","xver":0,"serverNames":["www.lovelive-anime.jp"],"privateKey":"$pri","shortIds":["$sid"]}}}],"outbounds":[{"protocol":"freedom"}]}
EOF
    systemctl restart xray
    show_config
}

echo -e "${green}1. 安装  2. 卸载  3. 查看配置  0. 退出${plain}"
read -p "选择: " num
case "$num" in
    1) install_base && bash <(curl -L https://github.com) && generate_config ;;
    2) bash <(curl -L https://github.com) --remove ;;
    3) show_config ;;
    *) exit 0 ;;
esac

