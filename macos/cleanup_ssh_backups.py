#!/usr/bin/env python3
import os
import sys
import glob
import datetime


def cleanup_ssh_backups():
    backup_dir = "/etc/ssh"
    backup_pattern = "ssh_config.bak_*"

    # 检查 root 权限
    if os.geteuid() != 0:
        print("错误：需要 root 权限运行此脚本")
        print("请使用: sudo python3 cleanup_ssh_backups.py")
        sys.exit(1)

    # 获取所有备份文件
    backup_files = glob.glob(os.path.join(backup_dir, backup_pattern))

    if not backup_files:
        print("未找到 SSH 配置备份文件")
        return

    print("找到以下备份文件:")
    for file_path in backup_files:
        print(f" - {os.path.basename(file_path)}")

    # 确认删除
    confirm = input("\n是否要删除这些备份文件？(y/n): ").strip().lower()
    if confirm != "y":
        print("操作已取消")
        return

    # 删除文件
    deleted_count = 0
    for file_path in backup_files:
        try:
            os.remove(file_path)
            print(f"已删除: {os.path.basename(file_path)}")
            deleted_count += 1
        except Exception as e:
            print(f"删除 {os.path.basename(file_path)} 失败: {e}")

    print(f"\n成功删除 {deleted_count}/{len(backup_files)} 个备份文件")


if __name__ == "__main__":
    cleanup_ssh_backups()
