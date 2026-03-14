--- === WiFiProxy ===
local obj = {}
obj.__index = obj

-- 元数据
obj.name = "WiFiProxy"
obj.version = "1.1"
obj.author = "Puyunfeng"

-- 配置默认值
obj.targetSSID = "Redmi K60 Ultra"
obj.defaultProxyPort = "2080"
obj.proxyAddressMode = "gateway"
obj.serviceName = "Wi-Fi"

local log = hs.logger.new('WiFiProxy', 'info')
local proxyEnvPath = os.getenv("HOME") .. "/.proxy_env"
local lastSSID = nil
local wifiWatcher = nil

-- 探测网关 IP
local function getGatewayIP()
    local ip = nil
    for i = 1, 3 do
        local handle = io.popen("netstat -rn | grep 'default' | awk '{print $2}' | head -n 1")
        local result = handle and handle:read("*all"):gsub("%s+", "") or ""
        if handle then handle:close() end
        if result:match("^%d+%.%d+%.%d+%.%d+$") and result ~= "127.0.0.1" then
            ip = result
            break
        end
        if i < 3 then hs.timer.usleep(1000000) end 
    end
    return ip or "127.0.0.1"
end

-- 写入独立代理文件 (保护 .zshrc)
local function setShellProxy(enable, ip, port)
    local content = "# Hammerspoon Auto-Generated\n"
    if enable then
        content = content .. string.format('export http_proxy="http://%s:%s"\n', ip, port)
        content = content .. string.format('export https_proxy="http://%s:%s"\n', ip, port)
        content = content .. string.format('export all_proxy="socks5://%s:%s"\n', ip, port)
        content = content .. 'export no_proxy="localhost,127.0.0.1,local,.local"\n'
    end
    local f = io.open(proxyEnvPath, "w")
    if f then f:write(content); f:close() end
end

-- 切换代理状态
local function setProxy(self, enable)
    local ip = "127.0.0.1"
    if enable and self.proxyAddressMode == "gateway" then ip = getGatewayIP() end
    
    log:i(string.format("🔄 Proxy %s | %s:%s", enable and "ON" or "OFF", ip, self.defaultProxyPort))

    if enable then
        local cmd = string.format(
            "networksetup -setwebproxy '%s' %s %s && networksetup -setwebproxystate '%s' on && " ..
            "networksetup -setsecurewebproxy '%s' %s %s && networksetup -setsecurewebproxystate '%s' on",
            self.serviceName, ip, self.defaultProxyPort, self.serviceName, self.serviceName, ip, self.defaultProxyPort, self.serviceName
        )
        hs.execute(cmd)
        setShellProxy(true, ip, self.defaultProxyPort)
        hs.notify.new({title="🎯 WiFiProxy", informativeText="✅ 代理开启: " .. ip}):send()
    else
        local cmd = string.format(
            "networksetup -setwebproxystate '%s' off && networksetup -setsecurewebproxystate '%s' off",
            self.serviceName, self.serviceName
        )
        hs.execute(cmd)
        setShellProxy(false)
        hs.notify.new({title="🎯 WiFiProxy", informativeText="❌ 代理已关闭"}):send()
    end
end

function obj:start()
    if wifiWatcher then wifiWatcher:stop() end
    wifiWatcher = hs.wifi.watcher.new(function()
        local currentSSID = hs.wifi.currentNetwork()
        if currentSSID == lastSSID then return end
        if lastSSID == self.targetSSID then setProxy(self, false) end
        if currentSSID == self.targetSSID then
            hs.timer.doAfter(2, function() setProxy(self, true) end)
        end
        lastSSID = currentSSID
    end)
    wifiWatcher:start()
    
    -- 启动检查
    if hs.wifi.currentNetwork() == self.targetSSID then setProxy(self, true) end
    return self
end

function obj:stop()
    if wifiWatcher then wifiWatcher:stop() end
    return self
end

return obj -- ⚠️ 确保这一行存在！