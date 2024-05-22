#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "此操作需要 root 权限，请使用 root 身份执行此脚本。"
    exit 1
fi

LOG_FILE="/var/log/ss-script.log"
log() {
    local msg="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg" >> "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg"
}

# 函数：安装软件包
install_package() {
    local package_name="$1"
    log "安装 $package_name..."
    dnf install -y "$package_name" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "无法安装 $package_name，请检查日志文件 $LOG_FILE 查看详细信息。"
        exit 1
    fi
}

# 检查 jq 是否安装，如果没有安装则进行安装
if ! command -v jq &> /dev/null; then
    read -p "未发现 jq 工具，是否安装？(y/n): " choice
    if [ "$choice" = "y" ]; then
        install_package "jq"
    else
        log "jq 工具未安装，退出安装过程。"
        exit 1
    fi
fi

# 创建目录
rm -rf ./tmp
mkdir -p ./tmp
mkdir -p /etc/shadowsocks

# v2ray-plugin 下载与安装
v2ray_plugin_repo="https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest"
v2ray_plugin_assets=$(curl -s $v2ray_plugin_repo | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')
if [ -n "$v2ray_plugin_assets" ]; then
    for url in $v2ray_plugin_assets; do
        log "下载 v2ray plugin from $url"
        curl -L -o ./tmp/v2ray-plugin.tar.gz "$url"
        tar -xzf ./tmp/v2ray-plugin.tar.gz -C ./tmp
        break
    done
else
    log "未找到 v2ray plugin 的最新版本。"
fi
install -m 755 ./tmp/v2ray-plugin_linux_amd64 /bin/v2ray-plugin

# shadowsocks 下载与安装
shadowsocks_repo="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
shadowsocks_assets=$(curl -s $shadowsocks_repo | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-gnu")) | .browser_download_url')
if [ -n "$shadowsocks_assets" ]; then
    for url in $shadowsocks_assets; do
        log "下载 shadowsocks from $url"
        curl -L -o ./tmp/shadowsocks.tar.xz "$url"
        tar -xJf ./tmp/shadowsocks.tar.xz -C ./tmp
        break
    done
else
    log "未找到 shadowsocks 的最新版本。"
fi
install -m 755 ./tmp/ssserver /bin/ssserver
install -m 755 ./tmp/ssservice /bin/ssservice
install -m 755 ./tmp/ssmanager /bin/ssmanager
install -m 755 ./tmp/ssurl /bin/ssurl

# 安装服务
if ! id -u shadowsocks &>/dev/null; then
    log "创建 shadowsocks 用户..."
    useradd -M -s /usr/sbin/nologin shadowsocks
fi

log "生成shadowsocks配置文件到 /etc/shadowsocks/"
cp ./template/config.json /etc/shadowsocks

log "生成服务配置文件到 /etc/systemd/system/"
cp ./template/shadowsocks.service /etc/systemd/system/shadowsocks.service

log "设置配置文件权限..."
chown -R shadowsocks:shadowsocks /etc/shadowsocks

log "安装设置密码..."
./update_password.sh

log "启动 shadowsocks 服务..."
systemctl daemon-reload
systemctl enable --now shadowsocks
log "安装 shadowsocks 服务完成"

sleep 1s
systemctl status shadowsocks