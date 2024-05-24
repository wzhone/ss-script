#!/bin/bash
source ./common.sh
source ./update.sh
source ./install.sh
source ./cn.sh
source ./rotate_key.sh
source ./uninstall.sh

check_root() {
    # 检查是否为 root 用户
    if [ "$(id -u)" -ne 0 ]; then
        echo "此操作需要 root 权限，请使用 root 身份执行此脚本。"
        exit 1
    fi
}

print_help() {
    echo "用法: $0 [install|uninstall|update|log|rotate|help|version|enhance]"
    echo ""
    echo "命令说明:"
    echo "  install   安装Shadowsocks套件"
    echo "  uninstall 卸载Shadowsocks套件"
    echo "  log       查看日志"
    echo "  rotate    执行密钥轮转"
    echo "  help      显示帮助信息"
    echo "  version   显示版本信息"
    echo "  enhance   屏蔽发往中国的请求"
}

command=""
flag_y=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    -y)
        flag_y=true
        ;;
    *)
        command=$1
        ;;
    esac
    shift
done

# 检查命令并执行相应的方法
case "$command" in
"install")
    check_root
    detect_os
    install_suit
    ;;
"update")
    check_root
    detect_os
    update_suit
    ;;
"log")
    /usr/bin/more $LOG_FILE
    ;;
"enhance")
    check_root
    detect_os
    enhance
    ;;
"rotate")
    check_root
    detect_os
    if [ "$flag_y" = true ]; then
        rotate_key
    else
        read -p "密钥轮转即时生效，是否轮转？(y/[N]): " choice
        if [ "$choice" = "y" ]; then
            rotate_key
        else
            exit 1
        fi
    fi
    ;;
"uninstall")
    check_root
    detect_os

    if [ "$flag_y" = true ]; then
        uninstall_suit
    else
        read -p "卸载不会保留配置文件，是否卸载？(y/[N]): " choice
        if [ "$choice" = "y" ]; then
            uninstall_suit
            uninstall_enhance
        else
            exit 1
        fi
    fi
    ;;
"help")
    print_help
    ;;
"version")
    echo $VERSION
    ;;
*)
    if [ -z "$1" ]; then
        print_help
    else
        echo "未知的命令: $1"
        print_help
    fi
    ;;
esac
