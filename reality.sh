#!/bin/bash

# REALITY 一键安装脚本
RED="\033[31m"   # Error message
GREEN="\033[32m" # Success message
YELLOW="\033[33m"# Warning message
BLUE="\033[36m"  # Info message
PLAIN='\033[0m'

NAME="xray"
CONFIG_FILE="/usr/local/etc/${NAME}/config.json"
SERVICE_FILE="/etc/systemd/system/${NAME}.service"

colorEcho() {
  echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
  result=$(id | awk '{print $1}')
  if [[ $result != "uid=0(root)" ]]; then
    colorEcho $RED " 请以 root 身份执行该脚本"
    exit 1
  fi
  res=$(which yum 2>/dev/null)
  if [[ "$?" != "0" ]]; then
    res=$(which apt 2>/dev/null)
    if [[ "$?" != "0" ]]; then
      colorEcho $RED " 不受支持的 Linux 系统"
      exit 1
    fi
    PMT="apt"
    CMD_INSTALL="apt install -y "
    CMD_REMOVE="apt remove -y "
    CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
  else
    PMT="yum"
    CMD_INSTALL="yum install -y "
    CMD_REMOVE="yum remove -y "
    CMD_UPGRADE="yum update -y"
  fi
  res=$(which systemctl 2>/dev/null)
  if [[ "$?" != "0" ]]; then
    colorEcho $RED " 系统版本过低，请升级到最新版本"
    exit 1
  fi
}

status() {
  export PATH=/usr/local/bin:$PATH
  cmd="$(command -v xray)"
  if [[ "$cmd" = "" ]]; then
    echo 0
    return
  fi
  if [[ ! -f $CONFIG_FILE ]]; then
    echo 1
    return
  fi
  port=$(grep -o '"port": [0-9]*' $CONFIG_FILE | awk '{print $2}')
  if [[ -n "$port" ]]; then
    res=$(ss -ntlp| grep ${port} | grep xray)
    if [[ -z "$res" ]]; then
      echo 2
    else
      echo 3
    fi
  else
    echo 2
  fi
}

statusText() {
  res=$(status)
  case $res in
    2) echo -e ${GREEN}已安装 xray${PLAIN} ${RED}未运行${PLAIN} ;;
    3) echo -e ${GREEN}已安装 xray${PLAIN} ${GREEN}正在运行${PLAIN} ;;
    *) echo -e ${RED}未安装 xray${PLAIN} ;;
  esac
}

preinstall() {
  $PMT clean all
  [[ "$PMT" = "apt" ]] && $PMT update

  echo ""
  echo "安装必要软件，请等待…"

  if [[ "$PMT" = "apt" ]]; then
    res=$(which ufw 2>/dev/null)
    [[ "$?" != "0" ]] && $CMD_INSTALL ufw
  fi

  res=$(which curl 2>/dev/null)
  [[ "$?" != "0" ]] && $CMD_INSTALL curl

  res=$(which openssl 2>/dev/null)
  [[ "$?" != "0" ]] && $CMD_INSTALL openssl

  res=$(which qrencode 2>/dev/null)
  [[ "$?" != "0" ]] && $CMD_INSTALL qrencode

  res=$(which jq 2>/dev/null)
  [[ "$?" != "0" ]] && $CMD_INSTALL jq
}

installXray() {
  echo ""
  echo "正在安装 Xray…"
  bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" > /dev/null 2>&1
  colorEcho $BLUE "Xray 内核已安装完成"
  sleep 5
}

updateXray() {
  echo ""
  echo "正在更新 Xray…"
  bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" > /dev/null 2>&1
  colorEcho $BLUE "Xray 内核已更新完成"
  sleep 5
}

removeXray() {
  echo ""
  echo "正在卸载 Xray…"
  bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge > /dev/null 2>&1
  rm -rf /etc/systemd/system/xray.service > /dev/null 2>&1
  rm -rf /usr/local/bin/xray > /dev/null 2>&1
  rm -rf /usr/local/etc/xray > /dev/null 2>&1
  rm -rf /usr/local/share/xray > /dev/null 2>&1
  rm -rf /var/log/xray > /dev/null 2>&1
  colorEcho $RED "Xray 卸载完成"
  sleep 5
}

# 脚本逻辑等其他函数未删…
# 如果你需要完整菜单、生成 config.json 等功能
# 我也可以帮你整理成一个干净版本供 GitHub 上传

