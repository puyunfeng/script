#!/usr/bin/env python3
import os
import sys
import re
import shutil
import datetime


def check_and_set_ssh_keepalive():
    ssh_config_path = "/etc/ssh/ssh_config"
    backup_path = ""
    required_settings = {"ServerAliveInterval": "30", "ServerAliveCountMax": "2"}

    # 检查root权限
    if os.geteuid() != 0:
        print("错误：需要root权限运行此脚本")
        print("请使用: sudo python3 script.py")
        sys.exit(1)

    # 检查文件是否存在
    if not os.path.exists(ssh_config_path):
        print(f"错误：文件 {ssh_config_path} 不存在")
        sys.exit(1)

    try:
        with open(ssh_config_path, "r") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"读取文件错误: {e}")
        sys.exit(1)

    # 检查是否已存在正确的配置
    settings_found = {key: False for key in required_settings}

    pattern = re.compile(r"^\s*(\w+)\s+(\d+)\s*$", re.IGNORECASE)

    for i, line in enumerate(lines):
        match = pattern.match(line.strip())
        if match:
            key, value = match.groups()
            if key in required_settings and value == required_settings[key]:
                settings_found[key] = True

    # 所有设置都已存在
    if all(settings_found.values()):
        print("SSH保活配置已存在且正确")
        return

    # 添加缺失的设置
    modified = False
    for key, value in required_settings.items():
        if not settings_found[key]:
            setting_line = f"{key} {value}\n"
            lines.append(setting_line)
            modified = True
            print(f"已添加: {setting_line.strip()}")

    if modified:
        try:
            # 创建备份文件
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = f"{ssh_config_path}.bak_{timestamp}"
            shutil.copy2(ssh_config_path, backup_path)
            print(f"已创建备份文件: {backup_path}")

            # 写入新配置
            with open(ssh_config_path, "w") as f:
                f.writelines(lines)
            print("SSH保活配置已成功设置")
        except Exception as e:
            print(f"写入文件错误: {e}")
            # 尝试恢复备份
            if backup_path and os.path.exists(backup_path):
                try:
                    shutil.copy2(backup_path, ssh_config_path)
                    print(f"已恢复备份文件: {backup_path}")
                except Exception as restore_error:
                    print(f"恢复备份失败: {restore_error}")
            sys.exit(1)
    else:
        print("SSH保活配置已存在")


if __name__ == "__main__":
    check_and_set_ssh_keepalive()
