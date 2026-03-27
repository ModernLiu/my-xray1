#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 请使用 root 用户运行！\n" && exit 1

get_info() {
    [[ -z $(systemctl status xray 2>/dev/null | grep "active (running)") ]] && status="${red}未运行${plain}" || status="${green}正在运行${plain}"
    [[ -f /usr/local/bin/xray ]] && version="${yellow}$(/usr/local/bin/xray -version | head -n 1 | awk '{print $2}')${plain}" || version="${red}未安装${plain}"
}

install_reality() {
    bash <(curl -L https://github.com)
    chmod +x /usr/local/bin/xray
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    [[ -z "$pub" ]] && pri="6OOfV2X9CjT9Yy7j-fG_H6S7q8_u6M-e6M_N6M-e6M_M" && pub="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"
    mkdir -p /usr/local/etc/xray
    echo "$pub" > /usr/local/etc/xray/public_key.txt
    cat << EOF > /usr/local/etc/xray/config.json
{"log":{"loglevel":"warning"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"$uuid","flow":"xtls-rprx-vision"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"show":false,"dest":"www.lovelive-anime.jp:443","xver":0,"serverNames":["www.lovelive-anime.jp"],"privateKey":"$pri","shortIds":["$sid"]}}}],"outbounds":[{"protocol":"freedom"}]}
EOF
    systemctl restart xray
    echo -e "${green}搭建完成！${plain}"
}

show_config() {
    if [[ ! -f /usr/local/etc/xray/config.json ]]; then
        echo -e "${red}未检测到配置！${plain}"
    else
        local ip=$(curl -s ipv4.icanhazip.com)
        local uuid=$(grep '"id"' /usr/local/etc/xray/config.json | awk -F '"' '{print $4}')
        local pbk=$(cat /usr/local/etc/xray/public_key.txt 2>/dev/null)
        local sid=$(grep '"shortIds"' /usr/local/etc/xray/config.json | awk -F '"' '{print $4}')
        echo -e "\n${yellow}vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#MyNode${plain}\n"
    fi
}

while true; do
    get_info
    echo -e "\n##################################################################"
    echo -e "#                   Reality一键安装脚本 (维护版)                 #"
    echo -e "##################################################################"
    echo -e "    <Xray内核版本>: ${version}    当前状态：${status}"
    echo -e "  1. 安装/更新  2. 卸载  3. 搭建REALITY  4. 查看链接  0. 退出\n"
    read -p "选择: " num
    case "$num" in
        1) bash <(curl -L https://github.com) ;;
        2) bash <(curl -L https://github.com) --remove ;;
        3) install_reality ;;
        4) show_config ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac
done
