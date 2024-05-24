#!/bin/bash

merged_file="sss.sh"

echo "#!/bin/bash" >$merged_file

script_files=(
    "./src/common.sh"
    "./src/cn.sh"
    "./src/rotate_key.sh"
    "./src/install.sh"
    "./src/uninstall.sh"
    "./src/update.sh"
    "./src/ss-script.sh"
) # 添加所有的脚本文件

# 遍历待合并的脚本文件
for script_file in "${script_files[@]}"; do
    # 检查脚本文件是否存在
    if [[ -f "$script_file" ]]; then
        # 将每个脚本文件的内容追加到合并后的文件中，去除source命令和shebang行
        sed '/^source/d;/^\s*#/d;/^\s*$/d' "$script_file" >>$merged_file
    else
        echo "文件 $script_file 未找到"
        exit 1
    fi
done

# 赋予执行权限
chmod +x $merged_file

if ! command -v shc &>/dev/null; then
    echo "shc未安装，正在安装..."

    # 更新包列表并安装shc
    if [[ -x "$(command -v apt)" ]]; then
        sudo apt update
        sudo apt install -y shc
    elif [[ -x "$(command -v yum)" ]]; then
        sudo yum install -y shc
    elif [[ -x "$(command -v dnf)" ]]; then
        sudo dnf install -y shc
    else
        echo "无法确定包管理器，请手动安装shc。" >&2
        exit 1
    fi

    if ! command -v shc &>/dev/null; then
        echo "shc安装失败，请手动安装。" >&2
        exit 1
    fi
fi

# 编译合并后的脚本
shc -f $merged_file -o sss -r