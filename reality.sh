#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (维护版)
# ====================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 核心功能逻辑开始
cur_dir=$(pwd)

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 检查系统版本
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif grep -Eqi "debian" /etc/issue; then
    release="debian"
elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
elif grep -Eqi "debian" /proc/version; then
    release="debian"
elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
fi

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

# 脚本主菜单 (完全保留原版样式)
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

# 搭建REALITY核心逻辑 (完全保留原脚本实现)
install_reality() {
    # 这里会自动调用官方安装脚本
    bash <(curl -L https://github.com)
    
    # 自动生成UUID/密钥对/ShortID
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local private_key=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local public_key=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local short_id=$(openssl rand -hex 8)
    
    # 写入配置 (默认443，如需8443请手动修改下方port)
    mkdir -p /usr/local/etc/xray
    cat << EOF > /usr/local/etc/xray/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [{"id": "$uuid", "flow": "xtls-rprx-vision"}],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.lovelive-anime.jp:443",
                "xver": 0,
                "serverNames": ["www.lovelive-anime.jp"],
                "privateKey": "$private_key",
                "shortIds": ["$short_id"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    systemctl restart xray
    echo -e "${green}搭建完成！${plain}"
    # 保存公钥方便查看
    echo "$public_key" > /usr/local/etc/xray/public_key.txt
}

# 逻辑控制
main() {
    show_menu
    read -p "请输入数字:" num
    case "$num" in
        1) bash <(curl -L https://github.com) ;;
        2) bash <(curl -L https://github.com) ;;
        3) bash <(curl -L https://github.com) --remove ;;
        4) install_reality ;;
        5) # 这里是查看链接的逻辑
           local ip=$(curl -s ipv4.icanhazip.com)
           local uuid=$(cat /usr/local/etc/xray/config.json | grep id | awk -F '"' '{print $4}')
           local pbk=$(cat /usr/local/etc/xray/public_key.txt)
           local sid=$(cat /usr/local/etc/xray/config.json | grep shortIds | awk -F '"' '{print $4}')
           echo -e "vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#Reality_Node"
           ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac
}

main

