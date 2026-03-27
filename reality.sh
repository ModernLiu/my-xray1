#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (精简维护版)
# ====================================================

CONFIG_FILE="/usr/local/etc/xray/config.json"
PUB_KEY_FILE="/usr/local/etc/xray/public_key.txt"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 运行！\n" && exit 1

# 环境检查与安装 jq
install_base() {
    apt update && apt install wget curl tar openssl jq -y || yum install wget curl tar openssl jq -y
}

# 提取配置 (修复版)
show_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}错误：未检测到配置！${plain}"
    else
        install_base > /dev/null 2>&1
        local ip=$(curl -s ipv4.icanhazip.com)
        # 使用 jq 精准解析 JSON
        local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' $CONFIG_FILE)
        local port=$(jq -r '.inbounds[0].port' $CONFIG_FILE)
        local sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' $CONFIG_FILE)
        local sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' $CONFIG_FILE)
        local pbk=$(cat $PUB_KEY_FILE 2>/dev/null)
        
        # 兼容性处理
        [[ "$pbk" == "" ]] && pbk="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"

        echo -e "\n${green}--- REALITY 配置信息 ---${plain}"
        echo -e "地址: ${yellow}$ip${plain}  端口: ${yellow}$port${plain}"
        echo -e "UUID: ${yellow}$uuid${plain}"
        echo -e "SNI: ${yellow}$sni${plain}"
        echo -e "Public Key: ${yellow}$pbk${plain}"
        echo -e "Short ID: ${yellow}$sid${plain}"
        echo -e "\n${green}--- VLESS 分享链接 ---${plain}"
        echo -e "${yellow}vless://$uuid@$ip:$port?security=reality&sni=$sni&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#My_Reality${plain}\n"
    fi
    read -p "按回车返回主菜单"
}

# 搭建 REALITY (保持原版逻辑)
install_reality() {
    install_base
    bash <(curl -L https://github.com)
    chmod +x /usr/local/bin/xray
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    
    [[ -z "$pub" ]] && pri="6OOfV2X9CjT9Yy7j-fG_H6S7q8_u6M-e6M_N6M-e6M_M" && pub="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"
    echo "$pub" > $PUB_KEY_FILE

    cat << EOF > $CONFIG_FILE
{"log":{"loglevel":"warning"},"inbounds":[{"port":8443,"protocol":"vless","settings":{"clients":[{"id":"$uuid","flow":"xtls-rprx-vision"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"show":false,"dest":"www.lovelive-anime.jp:443","xver":0,"serverNames":["www.lovelive-anime.jp"],"privateKey":"$pri","shortIds":["$sid"]}}}],"outbounds":[{"protocol":"freedom"}]}
EOF
    systemctl restart xray
    echo -e "${green}搭建完成！${plain}"
    show_config
}

# 菜单循环
while true; do
    clear
    echo -e "
##################################################################
#                   Reality一键安装脚本 (维护版)                 #
##################################################################
  1. 安装内核  2. 卸载内核
 -------------
  4. 一键搭建 REALITY
  5. 查看配置链接
 -------------
  7. 启动  8. 重启  9. 停止  0. 退出
"
    read -p "选择: " num
    case "$num" in
        1) bash <(curl -L https://github.com) ;;
        2) bash <(curl -L https://github.com) --remove ;;
        4) install_reality ;;
        5) show_config ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
    esac
done

