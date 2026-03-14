# WiFiProxy Spoon

一个 Hammerspoon Spoon，用于在连接指定 WiFi 时自动启用/关闭系统代理和 Shell 代理环境变量。

## 功能特性

- **自动检测 WiFi 变化**：监听当前连接的 WiFi 网络
- **智能代理切换**：当连接到指定 WiFi 时自动启用代理，断开时自动关闭
- **双重代理配置**：同时配置系统代理（通过 networksetup）和 Shell 代理环境变量（写入 ~/.proxy_env）
- **灵活的代理地址策略**：支持本机回环地址（127.0.0.1）或网关地址两种模式
- **自动网关探测**：在网关模式下自动探测当前网络的网关 IP
- **启动时自检**：启动时自动检查当前 WiFi 状态并应用相应配置
- **详细的日志记录**：提供完整的运行日志和系统通知

**注意**：本 Spoon 需要 Hammerspoon 的定位权限才能正常工作（macOS 安全要求）。

## 安装步骤

### 前置要求
- macOS 系统（已测试版本：macOS 13+）
- 已安装 Hammerspoon（[官网下载](https://www.hammerspoon.org/)）

### 安装步骤

1. 确保 Spoon 目录结构正确：
    ```bash
    ~/.hammerspoon/Spoons/WiFiProxy.spoon/init.lua
    ```

2. 在 Hammerspoon 配置文件中加载 Spoon（编辑 `~/.hammerspoon/init.lua`）：
    ```lua
    hs.loadSpoon("WiFiProxy")
    
    -- 配置参数
    spoon.WiFiProxy.targetSSID = "YourWiFiName"
    spoon.WiFiProxy.defaultProxyPort = "2080"
    spoon.WiFiProxy.proxyAddressMode = "gateway"
    spoon.WiFiProxy.serviceName = "Wi-Fi"
    
    -- 启动
    spoon.WiFiProxy:start()
    ```

3. 授予必要的系统权限：
    - **定位权限**（必需）：
      - 打开 Hammerspoon 控制台（Console）
      - 输入 `hs.location.start()` 并回车
      - 点击弹窗中的"允许"授予定位权限
      - 确认：`系统设置 → 隐私与安全性 → 定位服务` 中 Hammerspoon 已勾选

4. 重载配置：
    - 点击菜单栏的 Hammerspoon 图标
    - 选择 `Reload Config`

## 配置说明

在 `~/.hammerspoon/init.lua` 中配置 Spoon 参数：

```lua
hs.loadSpoon("WiFiProxy")

spoon.WiFiProxy.targetSSID = "Redmi K60 Ultra"      -- 目标 WiFi 网络名称
spoon.WiFiProxy.defaultProxyPort = "2080"           -- 代理端口
spoon.WiFiProxy.proxyAddressMode = "gateway"        -- 代理地址策略："loopback" 或 "gateway"
spoon.WiFiProxy.serviceName = "Wi-Fi"               -- 网络服务名称

spoon.WiFiProxy:start()
```

### 配置项详解

| 配置项 | 说明 | 可选值 | 示例 |
|--------|------|--------|------|
| `targetSSID` | 需要自动启用代理的 WiFi 名称 | 任意有效 SSID | `"MyWiFi"` |
| `defaultProxyPort` | 代理软件监听的端口 | 1-65535 | `"2080"` |
| `proxyAddressMode` | 代理地址策略 | `"loopback"` / `"gateway"` | 见下文 |
| `serviceName` | 系统网络服务名称 | 通常为 `"Wi-Fi"` | `"Wi-Fi"` |

### 代理地址策略说明

- **`"loopback"`**（推荐用于 Clash/Surge 等）：
   - 始终使用 `127.0.0.1` 作为代理地址
   - 适用于代理软件监听本机的场景
   - 兼容性最好，建议优先测试

- **`"gateway"`**（适用于共享代理设备）：
   - 自动探测并使用当前网络的网关 IP 地址
   - 适用于网关设备运行代理服务的场景
   - 内置重试机制，最多尝试 3 次

## Shell 代理配置

### 关键步骤：引入外部代理文件

为了让 Hammerspoon 生成的代理环境变量在新的终端会话中生效，需要在你的 shell 配置文件中添加以下内容：

**对于 zsh (macOS 默认)：**
```bash
# 在 ~/.zshrc 中添加
[[ -f ~/.proxy_env ]] && source ~/.proxy_env
```

**对于 bash：**
```bash
# 在 ~/.bashrc 中添加
[[ -f ~/.proxy_env ]] && source ~/.proxy_env
```

**说明：**
- Hammerspoon 只会修改 `~/.proxy_env` 文件
- 你的 shell 配置文件只需要 source 它，不会直接修改
- 这样可以保持 shell 配置文件整洁，避免 Hammerspoon 直接操作你的配置文件

## 使用方法

### 自动模式（推荐）
启动后自动监听 WiFi 变化：
- 连接到目标 WiFi → 2 秒后自动启用代理
- 断开目标 WiFi → 立即关闭代理
- 启动时自动检查并应用当前 WiFi 状态

### 手动控制
在 Hammerspoon 控制台中：

```lua
-- 停止监听
spoon.WiFiProxy:stop()

-- 重新启动
spoon.WiFiProxy:start()

-- 查看当前配置
print(spoon.WiFiProxy.targetSSID)
```

### 查看运行日志
在 Hammerspoon 控制台查看详细日志：
```
🔄 Proxy ON | 192.168.1.1:2080
🔄 Proxy OFF
```

### 查看运行日志
在 Hammerspoon 控制台查看详细日志：
```
✅ WiFiProxy 监控已启动，目标: Redmi K60 Ultra
🔍 开始探测网关 IP...
🎯 探测成功 (netstat): 192.168.1.1
🔄 代理 ON | 192.168.1.1:2080
```

### 状态通知
- 启用代理：显示代理地址和端口
- 关闭代理：显示关闭确认
- Terminal 代理配置：显示写入/清理状态

## 故障排查

### 常见问题

**1. WiFi 切换后代理没有生效**
- 检查 `targetSSID` 配置是否与实际 WiFi 名称完全一致（注意大小写和空格）
- 检查代理软件是否已启动并监听指定端口
- 查看控制台日志，确认是否检测到 WiFi 变化

**2. Shell 中代理环境变量未生效**
- 脚本将代理配置写入 `~/.proxy_env` 文件
- 在 Shell 中执行：`source ~/.proxy_env`
- 或在 `~/.zshrc` 中添加：`source ~/.proxy_env`

**3. 无法获取网关 IP**
- 检查是否已授予 Hammerspoon 定位权限
- 查看控制台日志中的错误信息
- 尝试将 `proxyAddressMode` 改为 `"loopback"`

**4. 代理开启但网络不通**
- 检查代理端口是否正确
- 确认代理地址模式是否适合当前网络环境
- 尝试切换 `proxyAddressMode` 配置

### 调试技巧
在 Hammerspoon 控制台执行：
```lua
-- 查看详细日志
hs.logger.new('WiFiProxy'):setLogLevel('debug')

-- 查看当前 WiFi
print(hs.wifi.currentNetwork())

-- 手动触发代理测试
hs.wifi.watcher.callback()
```

## 注意事项

### 安全提示
- 脚本会写入 `~/.proxy_env` 文件来配置 Shell 代理
- 代理切换会修改系统网络设置，请确保代理软件可信
- 定位权限是 macOS WiFi 监控的必需权限，不会收集位置数据

### 已知限制
- 不支持 WiFi 网络名称中包含特殊字符的情况
- 切换 WiFi 后有 2 秒延迟（等待 DHCP 分配 IP）
- Shell 代理需要手动 source `~/.proxy_env` 才能生效

### 兼容性
- macOS 13.0 及以上版本
- Hammerspoon 0.9.97 及以上版本
- 支持主流代理软件：Clash、Surge、Shadowsocks 等

### 性能影响
- 脚本资源占用极低，几乎无性能影响
- WiFi 监听为系统级监听，不影响网络速度
- 日志记录仅保留在内存中，不写入磁盘

## 卸载方法

### 停用 Spoon
1. 编辑 `~/.hammerspoon/init.lua`，删除或注释掉 Spoon 加载代码
2. 在 Hammerspoon 菜单栏选择 `Reload Config`

### 清理代理配置

**清理系统代理：**
```bash
networksetup -setwebproxystate "Wi-Fi" off
networksetup -setsecurewebproxystate "Wi-Fi" off
```

**清理 Shell 代理：**
```bash
rm ~/.proxy_env
```
并在 `~/.zshrc` 中移除 `source ~/.proxy_env` 行（如果已添加）。

### 撤销权限
- `系统设置 → 隐私与安全性 → 定位服务` → 取消勾选 Hammerspoon
- `系统设置 → 隐私与安全性 → 辅助功能` → 移除 Hammerspoon（如已添加）

## 附录

### 网络命令速查

| 命令 | 说明 |
|------|------|
| `hs.wifi.currentNetwork()` | 获取当前 WiFi 名称 |
| `networksetup -getinfo "Wi-Fi"` | 查看 WiFi 详细信息 |
| `networksetup -getwebproxy "Wi-Fi"` | 查看系统 HTTP 代理配置 |
| `netstat -rn | grep 'default'` | 查看网关 IP |

### 配置示例

**场景 1：家庭网络自动代理**
```lua
hs.loadSpoon("WiFiProxy")
spoon.WiFiProxy.targetSSID = "HomeNetwork"
spoon.WiFiProxy.defaultProxyPort = "1080"
spoon.WiFiProxy.proxyAddressMode = "loopback"
spoon.WiFiProxy:start()
```

**场景 2：公司网络使用网关代理**
```lua
hs.loadSpoon("WiFiProxy")
spoon.WiFiProxy.targetSSID = "CompanyWiFi"
spoon.WiFiProxy.defaultProxyPort = "8080"
spoon.WiFiProxy.proxyAddressMode = "gateway"
spoon.WiFiProxy:start()
```

**场景 3：多个代理软件切换**
```lua
-- Clash
spoon.WiFiProxy.defaultProxyPort = "7890"

-- Surge
spoon.WiFiProxy.defaultProxyPort = "6152"

-- Shadowsocks
spoon.WiFiProxy.defaultProxyPort = "1080"
```

### 日志级别说明

| 级别 | 说明 | 使用场景 |
|------|------|----------|
| `debug` | 最详细 | 开发调试 |
| `info` | 常规信息 | 正常使用（默认） |
| `warning` | 警告信息 | 非关键问题 |
| `error` | 错误信息 | 严重故障 |

## 版本历史

### v1.1 (当前版本)
- 重构为 Spoon 架构
- 将 Shell 代理配置从修改 ~/.zshrc 改为写入 ~/.proxy_env
- 添加 serviceName 配置项
- 改进网关 IP 探测的重试机制
- 优化通知显示

## 贡献指南

欢迎提交 Issue 和 Pull Request！

**报告问题时请包含：**
- macOS 版本
- Hammerspoon 版本
- 控制台错误日志
- 重现步骤

**提交代码时请：**
- 保持代码风格一致
- 添加必要的注释
- 测试在 macOS 13+ 上的兼容性

## 许可证

本项目采用 MIT 许可证。

**元数据：**
- 名称：WiFiProxy
- 版本：1.1
- 作者：Puyunfeng

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 查看 Hammerspoon 官方文档：[https://www.hammerspoon.org/](https://www.hammerspoon.org/)


# 4. 关键：引入外部代理文件（以后让 Hammerspoon 只动这个文件）
[[ -f ~/.proxy_env ]] && source ~/.proxy_env
