#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (维护版)
# ====================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 获取Xray状态
get_status() {
    if [[ -z $(systemctl status xray 2>/dev/null | grep "active (running)") ]]; then
        status="${red}未运行${plain}"
    else
        status="${green}正在运行${plain}"
    fi
}

# 获取Xray版本
get_version() {
    if [[ -f /usr/local/bin/xray ]]; then
        version="${yellow}$(/usr/local/bin/xray -version | head -n 1 | awk '{print $2}')${plain}"
    else
        version="${red}未安装xray${plain}"
    fi
}

# 菜单
show_menu() {
    get_status
    get_version
    clear
    echo -e "
##################################################################
#                   Reality一键安装脚本 (维护版)                 #
##################################################################
    <Xray内核版本>: ${version}
  1.  安装xray
  2.  更新xray
  3.  卸载xray
 -------------
  4.  搭建VLESS-Vision-uTLS-REALITY（xray）
  5.  查看reality链接
  6.  修改reality配置
 -------------
  7.  启动xray
  8.  重启xray
  9.  停止xray
 -------------
  10. 返回上一级菜单
  0.  退出
 当前xray状态：${status}

 请选择操作[0-10]："
}

# 安装/更新逻辑 (已修复链接)
do_install() {
    bash <(curl -L https://github.com)
}

# 搭建逻辑 (已修复链接)
install_reality() {
    do_install
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
    echo -e "${green}搭建完成！${plain}"
    sleep 2
}

# 提取配置
show_config() {
    if [[ ! -f /usr/local/etc/xray/config.json ]]; then
        echo -e "${red}错误：未检测到配置文件！${plain}"
    else
        local ip=$(curl -s ipv4.icanhazip.com)
        local uuid=$(grep '"id"' /usr/local/etc/xray/config.json | awk -F '"' '{print $4}')
        local pbk=$(cat /usr/local/etc/xray/public_key.txt)
        local sid=$(grep '"shortIds"' /usr/local/etc/xray/config.json | awk -F '"' '{print $4}')
        echo -e "\n${yellow}vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_NODE${plain}\n"
    fi
    read -p "按回车返回主菜单"
}

# 主循环
while true; do
    show_menu
    read -p "选择: " num
    case "$num" in
        1|2) do_install ;;
        3) bash <(curl -L https://github.com) --remove ;;
        4) install_reality ;;
        5) show_config ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac
done


main

