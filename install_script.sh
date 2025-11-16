#!/bin/bash

# 设置所有脚本的执行权限
set_script_permissions() {
    echo "设置脚本执行权限..."
    
    # 设置当前脚本的执行权限
    chmod +x "$0"
    
    # 递归查找并设置所有 .sh 和 .py 文件的执行权限
    find . -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    
    echo "所有脚本执行权限已设置"
}

# 检查是否为 root 用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "请使用 root 权限运行此脚本（使用 sudo）"
        echo "示例: sudo ./installScript.sh"
        exit 1
    fi
}

# 执行 SSH 保活配置
configure_ssh_keepalive() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local python_script="${script_dir}/macos/setup_ssh_keepalive.py"
    
    if [ ! -f "$python_script" ]; then
        echo "错误：找不到 SSH 保活配置脚本"
        echo "请确保文件位于: ${python_script}"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo "错误：Python3 未安装"
        echo "请先安装 Python3"
        exit 1
    fi
    
    echo "正在配置 SSH 保活设置..."
    python3 "$python_script"
    
    if [ $? -eq 0 ]; then
        echo "✅ SSH 保活配置成功"
    else
        echo "❌ SSH 保活配置失败"
        exit 1
    fi
}

# 清理 SSH 备份文件
cleanup_ssh_backups() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local python_script="${script_dir}/macos/cleanup_ssh_backups.py"
    
    if [ ! -f "$python_script" ]; then
        echo "错误：找不到清理脚本"
        echo "请确保文件位于: ${python_script}"
        exit 1
    fi
    
    echo "正在清理 SSH 配置备份文件..."
    python3 "$python_script"
    
    if [ $? -eq 0 ]; then
        echo "✅ 备份清理成功"
    else
        echo "❌ 备份清理失败"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: chmod +x install_script.sh & sudo ./install_script.sh [选项]"
    echo "选项:"
    echo "  --install     安装 SSH 保活配置（默认）"
    echo "  --clean       清理 SSH 配置备份文件"
    echo "  --help        显示此帮助信息"
    exit 0
}

# 主函数
main() {

    # 处理命令行参数
    case "$1" in
        --clean)
            check_root
            set_script_permissions
            cleanup_ssh_backups
            ;;
        --help)
            show_help
            ;;
        *)
            check_root
            set_script_permissions
            configure_ssh_keepalive
            echo "安装完成"
            ;;
    esac
}

main "$@"