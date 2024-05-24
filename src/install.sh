#!/bin/bash

source ./scripts/common.sh
source ./scripts/rotate_key.sh


# 检查并创建必要的目录
create_directories() {
    log "创建目录..."
    mkdir -p "$TMP_DIR"
    mkdir -p /etc/shadowsocks
}

# 下载并安装 v2ray plugin
install_v2ray_plugin() {
    local v2ray_plugin_repo="https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest"
    local v2ray_plugin_assets=$(curl -s "$v2ray_plugin_repo" | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')

    if [ -n "$v2ray_plugin_assets" ]; then
        for url in $v2ray_plugin_assets; do
            log "下载 v2ray plugin from $url"
            curl -L -s -o "$TMP_DIR/v2ray-plugin.tar.gz" "$url"
            tar -xzf "$TMP_DIR/v2ray-plugin.tar.gz" -C "$TMP_DIR"
            if [ -f "$TMP_DIR/v2ray-plugin_linux_amd64" ]; then
                /usr/bin/install -m 755 "$TMP_DIR/v2ray-plugin_linux_amd64" /bin/v2ray-plugin
                return 0
            else
                log "解压 v2ray plugin 失败"
                exit 1
            fi
        done
    else
        log "未找到 v2ray plugin 的最新版本。"
        exit 1
    fi
}

# 下载并安装 shadowsocks
install_shadowsocks() {
    local shadowsocks_repo="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
    local shadowsocks_assets=$(curl -s "$shadowsocks_repo" | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-gnu")) | .browser_download_url')

    if [ -n "$shadowsocks_assets" ]; then
        for url in $shadowsocks_assets; do
            log "下载 shadowsocks from $url"
            curl -L -s -o "$TMP_DIR/shadowsocks.tar.xz" "$url"
            tar -xJf "$TMP_DIR/shadowsocks.tar.xz" -C "$TMP_DIR"
            if [ -f "$TMP_DIR/ssserver" ] && [ -f "$TMP_DIR/ssservice" ] && [ -f "$TMP_DIR/ssmanager" ] && [ -f "$TMP_DIR/ssurl" ]; then
                /usr/bin/install -m 755 "$TMP_DIR/ssserver" /bin/ssserver
                /usr/bin/install -m 755 "$TMP_DIR/ssservice" /bin/ssservice
                /usr/bin/install -m 755 "$TMP_DIR/ssmanager" /bin/ssmanager
                /usr/bin/install -m 755 "$TMP_DIR/ssurl" /bin/ssurl
                return 0
            else
                log "解压 shadowsocks 失败"
                exit 1
            fi
        done
    else
        log "未找到 shadowsocks 的最新版本。"
        exit 1
    fi
}

# 创建 shadowsocks 用户
create_shadowsocks_user() {
    if ! id -u shadowsocks &>/dev/null; then
        log "创建 shadowsocks 用户..."
        useradd -M -s /usr/sbin/nologin shadowsocks
    fi
}

# 复制配置文件和服务文件，并设置权限
setup_shadowsocks_service() {
    log "生成 shadowsocks 配置文件到 /etc/shadowsocks/"
    cp ./template/config.json /etc/shadowsocks

    log "生成服务配置文件到 /etc/systemd/system/"
    cp ./template/shadowsocks.service /etc/systemd/system/shadowsocks.service

    log "设置配置文件权限..."
    chown -R shadowsocks:shadowsocks /etc/shadowsocks
}

# 启动 shadowsocks 服务
start_shadowsocks_service() {
    log "启动 shadowsocks 服务..."
    /usr/bin/systemctl daemon-reload
    /usr/bin/systemctl enable shadowsocks
    /usr/bin/systemctl start shadowsocks

    log "检查 shadowsocks 服务状态..."
    /usr/bin/systemctl status shadowsocks --no-pager | grep -E 'Active:|Loaded:'
}

# 安装 shadowsocks
install_suit() {
    log "开始安装 shadowsocks..."

    install_common_package jq

    create_directories
    install_v2ray_plugin
    install_shadowsocks
    create_shadowsocks_user
    setup_shadowsocks_service
    start_shadowsocks_service

    rotate_key

    log "安装 shadowsocks 服务完成"
}
