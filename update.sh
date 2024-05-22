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


# 创建目录
rm -rf ./tmp
mkdir -p ./tmp

# v2ray-plugin 下载与安装
v2ray_plugin_repo="https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest"
v2ray_plugin_assets=$(curl -s $v2ray_plugin_repo | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')
if [ -n "$v2ray_plugin_assets" ]; then
    for url in $v2ray_plugin_assets; do
        log "下载 v2ray plugin from $url"
        curl -L -s -o ./tmp/v2ray-plugin.tar.gz "$url"
        tar -xzf ./tmp/v2ray-plugin.tar.gz -C ./tmp
        break
    done
else
    log "未找到 v2ray plugin 的最新版本。"
fi

# shadowsocks 下载与安装
shadowsocks_repo="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
shadowsocks_assets=$(curl -s $shadowsocks_repo | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-gnu")) | .browser_download_url')
if [ -n "$shadowsocks_assets" ]; then
    for url in $shadowsocks_assets; do
        log "下载 shadowsocks from $url"
        curl -L -s -o ./tmp/shadowsocks.tar.xz "$url"
        tar -xJf ./tmp/shadowsocks.tar.xz -C ./tmp
        break
    done
else
    log "未找到 shadowsocks 的最新版本。"
fi


# 停止服务
log "停止shadowsocks服务..."
systemctl stop shadowsocks

log "安装shadowsocks文件..."
install -m 755 ./tmp/v2ray-plugin_linux_amd64 /bin/v2ray-plugin
install -m 755 ./tmp/ssserver /bin/ssserver
install -m 755 ./tmp/ssservice /bin/ssservice
install -m 755 ./tmp/ssmanager /bin/ssmanager
install -m 755 ./tmp/ssurl /bin/ssurl

# 启动服务
log "启动shadowsocks服务..."
systemctl daemon-reload
systemctl start shadowsocks
log "更新完成"
systemctl status shadowsocks --no-pager | grep -E 'Active:|Loaded:'
