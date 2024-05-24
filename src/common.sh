#!/bin/bash

VERSION="0.0.0"
TMP_DIR="/tmp/ss-script-tmp"
LOG_FILE="/var/log/ss-script.log"

log() {
    local msg="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg" >>"$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg"
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi
    log "检测到的操作系统: $OS"
}

install_common_package() {

    local package_name="$1"

    if command -v $package_name &>/dev/null; then
        return 0
    fi

    # 获取当前系统名称
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        current_system_name=$ID
    else
        echo "无法检测当前系统。"
        exit 1
    fi

    # 根据系统使用相应的包管理器安装包
    log "正在安装 $package_name ..."
    case "$current_system_name" in
    ubuntu | debian)
        apt-get update
        apt-get install -y "$package_name"
        ;;
    rockylinux | centos | fedora)
        dnf install -y "$package_name"
        ;;
    arch)
        pacman -Syu --noconfirm "$package_name"
        ;;
    *)
        log "不支持的系统：$current_system_name"
        exit 1
        ;;
    esac
    log "$package_name 安装成功。"
}

install_package() {
    local system_name="$1"
    local package_name="$2"

    # 获取当前系统名称
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        current_system_name=$ID
    else
        echo "无法检测当前系统。"
        exit 1
    fi

    if [ "$system_name" != "$current_system_name" ]; then
        return 0 # 系统不匹配，跳过安装
    fi

    # 检查是否已安装指定包
    if dpkg -l | grep -q "^ii  $package_name " || rpm -q "$package_name" >/dev/null 2>&1; then
        # echo "$package_name 已经安装。"
        return 0
    fi

    # 根据系统使用相应的包管理器安装包
    log "正在安装 $package_name ..."
    case "$current_system_name" in
    ubuntu | debian)
        apt-get update
        apt-get install -y "$package_name"
        ;;
    rockylinux | centos | fedora)
        dnf install -y "$package_name"
        ;;
    arch)
        pacman -Syu --noconfirm "$package_name"
        ;;
    *)
        echo "不支持的系统：$current_system_name"
        return 1
        ;;
    esac

    echo "$package_name 安装成功。"
}
