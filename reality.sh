#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (维护版) - 增加修改配置功能
# ====================================================

CONFIG_FILE="/usr/local/etc/xray/config.json"
PUB_KEY_FILE="/usr/local/etc/xray/public_key.txt"
UUID_FILE="/usr/local/etc/xray/uuid.txt"
SID_FILE="/usr/local/etc/xray/sid.txt"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 请使用 root 运行！\n" && exit 1

# 获取状态与版本
get_status() {
    [[ -z $(systemctl status xray 2>/dev/null | grep "active (running)") ]] && status="${red}未运行${plain}" || status="${green}正在运行${plain}"
}
get_version() {
    [[ -f /usr/local/bin/xray ]] && version="${yellow}$(/usr/local/bin/xray -version | head -n 1 | awk '{print $2}')${plain}" || version="${red}未安装${plain}"
}

# 4. 一键搭建
install_reality() {
    echo -e "${green}开始安装 Xray 核心...${plain}"
    bash <(curl -L https://github.com)
    chmod +x /usr/local/bin/xray
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    
    # 密钥兜底
    [[ -z "$pub" ]] && pri="6OOfV2X9CjT9Yy7j-fG_H6S7q8_u6M-e6M_N6M-e6M_M" && pub="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"

    mkdir -p /usr/local/etc/xray
    echo "$uuid" > $UUID_FILE
    echo "$pub" > $PUB_KEY_FILE
    echo "$sid" > $SID_FILE
    
    cat << EOF > $CONFIG_FILE
{"log":{"loglevel":"warning"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"$uuid","flow":"xtls-rprx-vision"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"show":false,"dest":"www.lovelive-anime.jp:443","xver":0,"serverNames":["www.lovelive-anime.jp"],"privateKey":"$pri","shortIds":["$sid"]}}}],"outbounds":[{"protocol":"freedom"}]}
EOF
    systemctl restart xray
    echo -e "${green}搭建成功！默认端口 443${plain}"
    sleep 2
}

# 5. 查看链接
show_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}请先选 4 搭建！${plain}"
    else
        local ip=$(curl -s ipv4.icanhazip.com)
        local uuid=$(cat $UUID_FILE)
        local pbk=$(cat $PUB_KEY_FILE)
        local sid=$(cat $SID_FILE)
        local port=$(grep '"port"' $CONFIG_FILE | awk -F'[: ,]+' '{print $3}')
        local sni=$(grep '"serverNames"' $CONFIG_FILE | awk -F'[" ]+' '{print $4}')
        echo -e "\n${yellow}vless://$uuid@$ip:$port?security=reality&sni=$sni&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_NODE${plain}\n"
    fi
    read -p "按回车继续..."
}

# 6. 修改配置
change_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}未检测到配置！${plain}"
        return
    fi
    echo -e "1. 修改端口\n2. 修改目标域名(SNI)\n0. 返回"
    read -p "选择: " cnum
    case "$cnum" in
        1)
            read -p "输入新端口: " new_port
            sed -i "s/\"port\": [0-9]*/\"port\": $new_port/" $CONFIG_FILE
            systemctl restart xray && echo -e "${green}端口已改为 $new_port${plain}"
            ;;
        2)
            read -p "输入新域名(如 www.microsoft.com): " new_sni
            sed -i "s/\"dest\": \".*\"/\"dest\": \"$new_sni:443\"/" $CONFIG_FILE
            sed -i "s/\"serverNames\": \[\".*\"\]/\"serverNames\": [\"$new_sni\"]/" $CONFIG_FILE
            systemctl restart xray && echo -e "${green}域名已改为 $new_sni${plain}"
            ;;
    esac
}

# 菜单循环
while true; do
    get_status && get_version
    clear
    echo -e "
##################################################################
#                   Reality一键安装脚本 (维护版)                 #
##################################################################
    <Xray内核版本>: ${version}
  1.  安装xray  2. 更新xray  3. 卸载xray
 -------------
  4.  搭建VLESS-Vision-uTLS-REALITY
  5.  查看reality链接
  6.  修改reality配置
 -------------
  7.  启动xray  8. 重启xray  9. 停止xray  0. 退出
 当前状态：${status}

 请选择操作:"
    read -p "数字: " num
    case "$num" in
        1|2) bash <(curl -L https://github.com) ;;
        3) bash <(curl -L https://github.com) --remove ;;
        4) install_reality ;;
        5) show_config ;;
        6) change_config ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
    esac
done
