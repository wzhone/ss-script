#!/bin/bash

source ./scripts/common.sh

check_env() {
    # 检查并安装 iptables, ipset 服务
    log "正在检查所需环境..."

    # 安装基础环境
    install_common_package ipset
    install_common_package iptables

    # 安装持久化服务
    install_package ubuntu iptables-persistent
    install_package debian iptables-persistent
    install_package rockylinux iptables-services
    install_package centos iptables-services
    install_package fedora iptables-services
    install_package arch iptables-persistent

    if ! command -v ipset &>/dev/null; then
        log "ipset 安装失败..."
        exit 1
    fi

    if ! command -v iptables &>/dev/null; then
        log "iptables 安装失败..."
        exit 1
    fi
}

enhance() {

    check_env

    local IPSET_NAME="cnips"
    local ZONE_FILE="/tmp/cn.zone"

    # 创建或重置 ipset
    log "重置ipset..."
    if ipset list -n | grep -q "^$IPSET_NAME$"; then
        ipset flush $IPSET_NAME
        ipset destroy $IPSET_NAME
    fi
    ipset create $IPSET_NAME hash:net

    # 下载并添加中国 IP 地址到 ipset
    log "从ipdeny下载中国IP范围..."
    curl -o $ZONE_FILE --retry 3 --retry-delay 5 http://www.ipdeny.com/ipblocks/data/countries/cn.zone
    if [[ $? -ne 0 ]]; then
        log "Failed to download IP address list. Exiting."
        exit 1
    fi
    while IFS= read -r ip; do
        ipset add $IPSET_NAME $ip
    done <$ZONE_FILE
    rm -f $ZONE_FILE

    # 配置 iptables 规则
    log "配置iptables规则..."

    # 清除之前的规则
    iptables -D OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j LOG --log-prefix "CHINA-REJECT: " --log-level 4 2>/dev/null
    iptables -D OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j REJECT -m comment --comment "Block connections to China IPs" 2>/dev/null

    # 添加规则
    iptables -A OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j LOG --log-prefix "CHINA-REJECT: " --log-level 4
    iptables -A OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j REJECT -m comment --comment "Block connections to China IPs"

    log "保存iptables规则..."

    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save
    else
        service iptables save
    fi

    log "防火墙规则已保存"
}

uninstall_enhance() {
    if ! command -v ipset &>/dev/null; then
        return
    fi

    if ! command -v iptables &>/dev/null; then
        return
    fi

    iptables -D OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j LOG --log-prefix "CHINA-REJECT: " --log-level 4 >/dev/null 2>&1
    iptables -D OUTPUT -p tcp -m set --match-set $IPSET_NAME dst -m conntrack --ctstate NEW -j REJECT -m comment --comment "Block connections to China IPs" >/dev/null 2>&1
    ipset destroy cnips >/dev/null 2>&1
    return 0
}
