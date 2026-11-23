--[[--
kofb.koplugin — 「网页文件管理器 2」的 KOReader 快捷方式（v1.1.6）

UI 文案按系统语言显示：系统为简体中文时显示中文，其它（含英文）显示英文。
判定依据为 KOReader 启动时已加载的 locale（require("gettext").current_lang，
中文为 "zh_CN" 等，英文/未设为 "C"/"en" 等）。

为什么自带桥接脚本，而不是直接调用 KUAL 包的 start.sh / stop.sh：
  * 那两个脚本结尾都会发 com.lab126.hal powerButtonPressed 事件「返回 Kindle 桌面」，
    并用 eips 直接写帧缓冲显示 IP。KOReader 在前台时，前者会把 KOReader 踢到后台，
    后者会被 KOReader 的界面重绘覆盖（甚至反过来破坏 KOReader 画面）。
  * 因此本插件改由自带的 fb_bridge.sh 完成启停：只做 放行 80 端口 / 后台拉起 filebrowser
    二进制，绝不回桌面、绝不写 eips、不拉起会写屏的 idle.sh。
  * v1.1.6 彻底移除「活动常亮」（本次）：crash.log 证实服务运行期（08:48–09:27）密集出现
    suspend/resume 震荡（25s/43s/36s/11s…），而服务关闭后震荡消失——元凶是 v1.1.0 引入的
    wake/sleep 写 powerd preventScreenSaver：传输时置 1 顶住挂起，v1.1.4 又把 sleep 推迟到
    onResume，若某次 suspend 未走到 onResume 则标记永久残留，表现为「锁屏后解锁不了、卡死」。
    本次彻底移除：kofb 完全不再写 preventScreenSaver，屏幕唤醒/息屏 100% 交给 KOReader 与系统，
    从根源消除震荡与锁屏卡死；仅 fb_bridge.sh 的 stop 保留一次清 0 兜底（兼容 KUAL 混合启动场景）。
  * v1.1.1 判定修复：数据传输/无传输的判定源由「整机网卡字节 /proc/net/dev」改为
    「filebrowser 进程自身 IO /proc/<pid>/io」—— 前者会被 Storefront 后台抓目录等无关流量污染，
    导致 ① 5 分钟无传输自动关闭永不触发 ② 活动常亮被虚假流量反复续期、顶住挂起锁不住屏。
    另为 onSuspend/onResume 的自动重启加防抖：suspend/resume 震荡窗口内不再反复 fork 启停服务。
  * v1.1.3 判定再修复（关键）：进程 IO 对 Go HTTP 服务的 sendfile 零拷贝无效 —— 下载/上传大文件
    不经用户态 read/write，rchar/wchar 不涨，导致「正在传输却判无传输、5 分钟误关」。改回内核层
    iptables 80 端口规则计数：只统计访问本服务的包（剔除其它程序联网），且 sendfile 同样经过
    netfilter 如实计数；并双向统计 INPUT dpt:80（请求/上传）+ OUTPUT spt:80（下载响应），
    杜绝「纯下载是出站流量」被漏判。一次 iptables -L 取两链，仅 1 次 fork。
  * v1.1.4 息屏卡死根治（本次）：crash.log 两次强制重启都发生在「服务运行中、等待自动关闭时息屏」，
    且日志无任何退出记录（正常退出都有 Tearing down / lipc-wait-event exited normally）。根因是
    onSuspend 在 suspend 电源关键路径里同步 io.popen fork shell + 对 powerd 的 preventScreenSaver
    做 LIPC 写，与系统息屏竞争而挂死。改为 onSuspend 只改内存状态：零 fork、零 LIPC、零阻塞；
    状态复查 / 常亮兜底 / 看护恢复全部推迟到 onResume（电源路径之外）异步执行。
  * v1.1.5 异步探针（本次）：crash.log 的 aat 心跳（每 2s）显示一次卡屏时事件循环停摆，
    卡点紧邻看护恢复，根因是看护/网络监听每轮在主线程同步 io.popen("sh fb_bridge.sh probe")，
    该命令含 iptables 全表遍历 + ifconfig×4 + ps，低内存 PW4 上、叠加 Storefront 后台联网时
    可长时间阻塞 UI 线程。改为后台 spawn 探针写缓存、主线程只读缓存文件（零 fork、零阻塞），
    彻底消除卡屏；菜单/启动等用户主动触发的即时查询仍用同步 probe，交互不受影响。
  * IP 用 KOReader 自己的菜单右侧值 / 弹窗显示，天然避开帧缓冲冲突。
  * 桥接脚本只依赖 Kindle 系统接口与现有包里的 filebrowser 二进制 / filebrowser.db，
    不 source lib.sh、不调用 start.sh，因此 KUAL 插件包后续升级不会破坏本插件。

本插件只是「快捷方式」，不含核心程序：依附项目开源地址与当前状态见菜单
「状态 / IP / 关于」，仅安装本插件的人员可据此补全依赖。

「快捷方式」体现在 Dispatcher：注册了 3 个动作，可在
  设置 → 手势 / 物理按键 / 快捷面板 里绑定到任意触发方式。
--]]--

local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local GetText = require("gettext")
local logger = require("logger")

-- 统一日志前缀：在 crash.log 中 grep "kofb:" 即可定位本插件行为，便于排查锁屏/自动关闭等问题。
-- 只在离散事件（启停/挂起/状态翻转）打日志，轮询热路径不打，避免低内存设备日志膨胀。
local function klog(...)
    logger.info("kofb:", ...)
end

-- 按系统语言返回中文或英文：KOReader 启动时已据系统语言加载对应 locale，
-- GetText.current_lang 为 "zh_CN" 等（中文）或 "C"/"en" 等（英文/其它）。
-- 每次调用都重新判定，可随 KOReader 运行时切换语言即时生效。
local function T(en, cn)
    local l = GetText.current_lang
        or os.getenv("LANG") or os.getenv("LC_ALL") or os.getenv("LANGUAGE") or ""
    return l:match("zh") and cn or en
end

-- 长文本（依赖项目地址 + 当前状态）用可滚动的 TextViewer 展示；
-- 老版本 KOReader 无该模块时自动回退到 InfoMessage，不影响插件加载。
local ok_tv, tv_module = pcall(require, "ui/widget/textviewer")
local TextViewer = (ok_tv and type(tv_module) == "table") and tv_module or nil

local PLUGIN_VERSION = "1.1.6"

-- 依赖项目开源地址：KUAL 扩展包「网页文件管理器 2」（提供核心程序）
local URL_KUAL_EXT = "https://github.com/Gh9518/kindle-filebrowser-optimized"

-- 自动关闭看护阈值（轮询间隔 WD_INTERVAL 秒，靠 KOReader 的 UIManager 调度）：
--   WD_OFFLINE_LIMIT × 10s = 约 2 分钟无网络即自动关闭；
--   WD_IDLE_LIMIT    × 10s = 约 5 分钟无数据传输即自动关闭。
-- 离线时两项都不变，但「无网络 2 分钟」先到，优先按离线关闭。
local WD_INTERVAL = 10
local WD_OFFLINE_LIMIT = 12
local WD_IDLE_LIMIT = 30

local KOFileBrowser = WidgetContainer:extend{
    name = "kofb",
    is_doc_only = false,   -- 文件管理器与阅读器界面都可用
}

-- 取插件自身目录：优先 debug 得到的真实路径，再按候选目录校验 fb_bridge.sh 是否存在
local function plugin_dir()
    local candidates = {}
    local ok, src = pcall(function() return debug.getinfo(1, "S").source end)
    if ok and src and src:sub(1, 1) == "@" then
        local d = src:match("^@(.*/)")
        if d then candidates[#candidates + 1] = d end
    end
    candidates[#candidates + 1] = "/mnt/us/koreader/plugins/kofb.koplugin/"
    candidates[#candidates + 1] = "/mnt/base-us/koreader/plugins/kofb.koplugin/"
    for _, d in ipairs(candidates) do
        local f = io.open(d .. "fb_bridge.sh", "r")
        if f then
            f:close()
            return d
        end
    end
    return candidates[1] or "/mnt/us/koreader/plugins/kofb.koplugin/"
end

local BRIDGE = plugin_dir() .. "fb_bridge.sh"

-- v1.1.5 异步探针缓存：后台 spawn("probe_file") 把「状态 IP 字节」原子写入此文件，
-- 主线程只读这个小文本文件（io.open + 一次 read），完全不再同步 fork 重量级 probe。
local PROBE_CACHE = "/tmp/kofb_probe.cache"

local function shquote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- 同步执行并取回 stdout（status / ip / dir / stop 这类快速命令）
local function capture(args)
    local cmd = "sh " .. shquote(BRIDGE) .. " " .. args .. " 2>/dev/null"
    local h = io.popen(cmd)
    if not h then return "" end
    local out = h:read("*a") or ""
    h:close()
    return (out:gsub("%s+$", ""))
end

-- 后台执行（start 内部有短轮询等端口就绪，放后台避免阻塞 KOReader 的 UI 线程）
local function spawn(args)
    os.execute("sh " .. shquote(BRIDGE) .. " " .. args .. " >/dev/null 2>&1 &")
end

-- 一次 fork 取回「<status> <ip> <bytes>」三态（桥接脚本 probe 子命令）。
-- 用于菜单 mandatory_func、启动/状态查看等「用户主动、低频」的即时查询：
-- 这些调用需要与界面同步拿到最新值，且频率低，同步 fork 不会阻塞热路径。
-- 返回 st, ip, bytes 三个字符串；解析失败时 st 为 nil。
local function probe()
    return capture("probe"):match("^(%S+) (%S+) (%S+)")
end

-- v1.1.5 异步探针（卡屏根治）——
-- 看护 / 网络恢复监听是「每 10 秒 / 每 3 秒」的高频热路径。旧版每轮在主线程同步
-- io.popen("sh fb_bridge.sh probe")，而 probe 内含 iptables 全表遍历 + ifconfig×4 + ps，
-- 在低内存 PW4 上、叠加 Storefront 后台联网时可长时间阻塞 KOReader 的 UI 线程 ——
-- crash.log 中 aat 心跳（每 2s）戛然而止、恰好停在看护恢复之后，正是此因。
-- 改造：probe_async() 后台 spawn 探针把结果原子写入缓存文件（立即返回、不等待）；
-- probe_cached() 只读缓存（一次 io.open + read，零 fork、零阻塞）。
-- 缓存不存在或残缺（首轮后台尚未完成）时回退一次同步 probe，仅此一次，不影响稳态。
local function probe_async()
    os.execute("sh " .. shquote(BRIDGE) .. " probe_file " .. shquote(PROBE_CACHE)
               .. " >/dev/null 2>&1 &")
end

local function probe_cached()
    local f = io.open(PROBE_CACHE, "r")
    if not f then return probe() end
    local line = f:read("*l")
    f:close()
    local parsed = line and line:match("^(%S+) (%S+) (%S+)")
    if not parsed then return probe() end
    return parsed
end

-- IP 形如 192.168.1.5 才算「已联网」；FB_ERR / 空 / 其它一律视为未联网
local function ip_valid(ip)
    return ip ~= nil and ip:match("^%d+%.%d+%.%d+%.%d+$") ~= nil
end

function KOFileBrowser:onDispatcherRegisterActions()
    Dispatcher:registerAction("kofb_start", {
        category = "none", event = "KOFBStart",
        title = T("Web File Browser: Start", "网页文件管理器：启动"), general = true,
    })
    Dispatcher:registerAction("kofb_stop", {
        category = "none", event = "KOFBStop",
        title = T("Web File Browser: Stop", "网页文件管理器：关闭"), general = true,
    })
    Dispatcher:registerAction("kofb_ip", {
        category = "none", event = "KOFBShowIP",
        title = T("Web File Browser: Status / IP", "网页文件管理器：状态 / IP"), general = true,
    })
end

function KOFileBrowser:init()
    klog("plugin loaded v" .. PLUGIN_VERSION .. ", bridge =", BRIDGE)
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function KOFileBrowser:addToMainMenu(menu_items)
    menu_items.kofb_filebrowser = {
        text = T("Web File Browser 2", "网页文件管理器 2"),
        -- 一级菜单：tools 是「工具」标签页本身（阅读器 / 文件管理器都存在）。
        -- 官方 menusorter.lua 会给该 tab 打 id="tools" 并把本项 insert 到其一级列表；
        -- 旧值 more_tools 是工具页下的「更多工具」子菜单，需多点一层；
        -- 不带 sorting_hint 则会被当成 orphan 丢进第一个标签页并加 "NEW: " 前缀。
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = T("Start", "启动"),
                -- 把 IP 直接显示在「启动」后面（菜单右侧值），无需再点任何子项。
                -- KOReader 每次展开菜单会调用 mandatory_func 取一次状态与 IP。
                mandatory_func = function()
                    local st, ip = probe()
                    if st ~= "on" then return T("Not started", "未启动") end
                    if not ip_valid(ip) then return T("No network", "未联网") end
                    return ip
                end,
                callback = function() self:onFBStart() end,
            },
            {
                text = T("Stop", "关闭"),
                callback = function() self:onFBStop() end,
            },
            {
                -- 合并项：当前状态 + 依赖项目开源地址，一次点开看全。
                text = T("Status / IP / About", "状态 / IP / 关于"),
                -- 右侧显示版本号，便于在设备上直接确认装的是哪一版（防旧包缓存）
                mandatory = "v" .. PLUGIN_VERSION,
                callback = function() self:showAbout() end,
            },
        },
    }
end

function KOFileBrowser:onFBStart()
    if capture("status") == "on" then
        -- 服务已在跑（例如先在 KUAL 里启动过）：只接管，停掉会写 eips 的守护，
        -- 然后居中提示当前 IP 即可（默认 80 端口，不显示端口号）。
        spawn("quiet")
        -- 接管后也启动自动关闭看护（与上面的「已启动」路径保持一致）
        self:_startWatchdog()
        local ip = capture("ip")
        local text
        if ip == "" or ip == "Offline" or ip:find("FB_ERR") then
            text = T("Service is already running, but currently no network.\n"
                      .. "It will pop up the device IP automatically once Wi-Fi is connected.",
                     "服务已在运行，但当前未联网。\n连上 WiFi 后会自动弹出本机 IP 提示。")
            -- 离线时启动恢复监听：联网后自动居中提示当前 IP
            self:_maybeWatchNetwork()
        else
            text = T("Current IP: http://", "当前 IP：http://") .. ip
        end
        self:showMessage(text, 5)
        return
    end
    spawn("start")
    local start_msg = InfoMessage:new{
        text = T("Starting Web File Browser in the background…\nKOReader stays on the current page.",
                  "正在后台启动网页文件管理器…\nKOReader 保持在当前页面。"),
        align = "center",
    }
    UIManager:show(start_msg)
    -- 桥接脚本内部会等 80 端口就绪（最长约 8 秒），这里轮询到就绪或超时再弹结果，
    -- 避免「正在启动」还没结束就误报失败；每 2 秒查一次，最多约 10 秒。
    self:_pollStart(start_msg, 0, self._resume_gen or 0)
end

-- 轮询启动结果：就绪则弹成功/未联网提示（5 秒自动关闭），超时则弹安装依赖提示（5 秒）。
-- 带 gen 代际：若启动轮询期间锁屏（suspend 自增 _resume_gen），残留回调直接作废，
-- 不在挂起窗口弹窗或启动看护 fork 子进程。
function KOFileBrowser:_pollStart(start_msg, n, gen)
    if gen ~= (self._resume_gen or 0) then
        UIManager:close(start_msg)
        return
    end
    if capture("status") == "on" then
        UIManager:close(start_msg)
        self:showStartResult()
        return
    end
    if n >= 5 then
        UIManager:close(start_msg)
        self:showStartResult()
        return
    end
    UIManager:scheduleIn(2, function()
        self:_pollStart(start_msg, n + 1, gen)
    end)
end

function KOFileBrowser:showStartResult()
    local st = capture("status")
    local text
    if st ~= "on" then
        klog("start FAILED (core not running)")
        text = T("Failed to start: could not launch the \"Web File Browser 2\" core program.\n\n",
                 "启动失败：未能启动「网页文件管理器 2」核心程序。\n\n")
            .. T("Please install the KUAL extension \"Web File Browser 2\" and have its core program in place first, "
                  .. "then come back and tap Start; see the menu \"Status / IP / About\" for the dependency's open-source address.",
                 "请先安装 KUAL 扩展包「网页文件管理器 2」并让核心程序就位，\n再回来点「启动」；依赖项目开源地址见菜单「状态 / IP / 关于」。")
    else
        -- 服务已就绪：启动自动关闭看护（无网络 2 分钟 / 无数据传输 5 分钟即关）
        self:_startWatchdog()
        local ip = capture("ip")
        if ip == "" or ip == "Offline" or ip:find("FB_ERR") then
            klog("start OK, no network yet (watcher armed)")
            text = T("Web File Browser has started, but there is no network connection now.\n"
                      .. "It will pop up the device IP automatically once Wi-Fi is connected.",
                     "网页文件管理器已启动，但当前未联网。\n连上 WiFi 后会自动弹出本机 IP 提示。")
            -- 离线时启动恢复监听：联网后自动居中提示当前 IP
            self:_maybeWatchNetwork()
        else
            -- 简洁：仅「启动成功，当前IP」，默认 80 端口，不写端口号
            klog("start OK, IP =", ip)
            text = T("Started. Current IP: http://", "启动成功，当前IP：http://") .. ip
        end
    end
    -- 成功与失败都只显示 5 秒后自动关闭，不再多弹窗
    self:showMessage(text, 5)
end

-- 网络恢复监听：服务已启动但暂未联网时，后台轮询本机 IP。
-- 一旦连上 WiFi 拿到 IP，就居中弹窗提示「网络已恢复，当前IP：http://…」，
-- 不必用户手动回去翻菜单。轮询有上限（最长约 2 分钟），超时即放弃、避免无谓占用。
-- 每轮只 fork 一个 probe 子进程；带代际令牌 gen：挂起 / 重启新监听后，旧定时回调自动作废。
function KOFileBrowser:_watchNetwork(n, gen)
    n = n or 0
    if not self._net_watch or gen ~= self._net_gen then return end
    -- v1.1.5 同样改读异步缓存并后台刷新，避免 3 秒一次同步 fork 阻塞 UI
    local st, ip = probe_cached()
    probe_async()
    if st ~= "on" then
        -- 服务已被关闭：停止监听
        self._net_watch = false
        return
    end
    if ip_valid(ip) then
        -- 网络已恢复：居中提示当前 IP（默认 80 端口，不显示端口号），5 秒后自动关闭
        klog("network recovered, IP =", ip)
        self._net_watch = false
        self:showMessage(
            T("Network is back. Current IP: http://", "网络已恢复，当前IP：http://") .. ip, 5)
        return
    end
    -- 最多约 2 分钟（40 次 × 3 秒）后放弃，避免一直占着 UI 调度
    if n >= 40 then
        self._net_watch = false
        return
    end
    UIManager:scheduleIn(3, function() self:_watchNetwork(n + 1, gen) end)
end

-- 启动网络恢复监听（去重：同一时刻只跑一个，避免重复弹窗）
function KOFileBrowser:_maybeWatchNetwork()
    if self._net_watch then return end
    self._net_watch = true
    self._net_gen = (self._net_gen or 0) + 1
    self:_watchNetwork(0, self._net_gen)
end

-- 自动关闭看护：服务运行期间轮询（每 WD_INTERVAL 秒一次，靠 KOReader 的 UIManager 调度）：
--   * 连续 WD_OFFLINE_LIMIT 次都拿不到 IP（无网络）-> 自动关闭，避免空占后台；
--   * 连续 WD_IDLE_LIMIT 次 80 端口累计字节都不变（无数据传输）-> 自动关闭，省电；
--     （判定源为 iptables 双向 80 端口计数，覆盖 sendfile 零拷贝的下载/上传，详见 fb_bridge.sh）
-- 离线时两项都不变，但「无网络 2 分钟」先到，优先按离线关闭。
-- 每轮只 fork 一个 probe 子进程（一次拿全 状态/IP/字节）；带代际令牌 gen：
-- 挂起 / 重启新看护后，残留的旧定时回调自动作废，不会出现双看护叠加轮询。
function KOFileBrowser:_startWatchdog()
    if self._wd then return end
    self._wd = true
    self._wd_gen = (self._wd_gen or 0) + 1
    self._wd_offline = 0          -- 连续无网络轮询次数
    self._wd_idle = 0             -- 连续无数据传输轮询次数
    local _, _, bytes = probe()
    self._wd_last_bytes = bytes
    self:_watchdogTick(self._wd_gen)
end

function KOFileBrowser:_watchdogTick(gen)
    -- 已被新一代看护取代 / 已停止：本轮作废
    if not self._wd or gen ~= self._wd_gen then return end
    -- v1.1.5 热路径零阻塞：只读上一轮后台探针写好的缓存（零 fork），
    -- 并立刻后台 spawn 下一轮刷新，主线程绝不等待 iptables/ifconfig/ps。
    local st, ip, bytes = probe_cached()
    probe_async()
    if st ~= "on" then
        -- 服务已停：看护结束
        self._wd = false
        return
    end
    local online = ip_valid(ip)
    if online then
        self._wd_offline = 0
    else
        self._wd_offline = self._wd_offline + 1
    end
    -- 约 2 分钟无网络即关闭
    if self._wd_offline >= WD_OFFLINE_LIMIT then
        self._wd = false
        self:_autoStop(T("No network for 2 minutes — Web File Browser has been auto-closed.",
                         "已持续 2 分钟无网络，网页文件管理器已自动关闭。"))
        return
    end
    -- 数据传输检测：iptables 80 端口双向累计字节（INPUT dpt:80 + OUTPUT spt:80）是否变化。
    -- 内核层统计只算访问本服务的包（剔除 Storefront 等无关联网），且 sendfile 零拷贝的
    -- 下载/上传同样计数 —— 修正 v1.1.1「进程 IO 对 sendfile 无效、传输中被误判无传输」的问题。
    local traffic = bytes and bytes ~= "" and bytes ~= self._wd_last_bytes
    if traffic then
        self._wd_last_bytes = bytes
        self._wd_idle = 0
    else
        self._wd_idle = self._wd_idle + 1
    end

    -- v1.1.6：不再写 preventScreenSaver。屏幕唤醒/息屏完全交给 KOReader 与系统，
    -- 彻底移除曾导致 suspend/resume 震荡、锁屏卡死的活动常亮机制。

    -- 约 5 分钟无数据传输即关闭
    if self._wd_idle >= WD_IDLE_LIMIT then
        self._wd = false
        self:_autoStop(T("Web File Browser closed after a period of inactivity.",
                         "长时间无数据传输，已关闭网页文件管理器"))
        return
    end
    UIManager:scheduleIn(WD_INTERVAL, function() self:_watchdogTick(gen) end)
end

-- 自动关闭并居中提示（5 秒）：不打扰前台 KOReader，也不写帧缓冲
-- v1.1.6：stop 命令内已兜底清 preventScreenSaver 0，插件侧不再写电源属性。
function KOFileBrowser:_autoStop(msg)
    klog("auto-close watchdog fired:", msg:gsub("\n", " "))
    capture("stop")
    self:showMessage(msg, 5)
end

function KOFileBrowser:onFBStop()
    local r = capture("stop")
    local ok = (r == "stopped")
    klog("stop requested, result =", ok and "stopped" or "failed")
    -- 关闭只提示是否成功：成功 2 秒后自动关闭，失败提示重试（5 秒）
    self:showMessage(ok and T("Web File Browser has been stopped.", "网页文件管理器已关闭。")
                          or T("Failed to stop. Please try again later.", "关闭失败，请稍后重试。"),
                     ok and 2 or 5)
end

-- 自动关闭的简短弹窗（timeout 秒后由 KOReader 自动关闭），用于启动结果 / 关闭结果；文字居中
function KOFileBrowser:showMessage(text, timeout)
    UIManager:show(InfoMessage:new{ text = text, show_icon = false, timeout = timeout, align = "center" })
end

-- 手动查看当前状态 / IP（菜单「状态 / IP / 关于」点击、手势「状态 / IP」、以及「服务已在运行」时使用）
function KOFileBrowser:showInfo(prefix)
    local st = capture("status")
    local ip = capture("ip")
    local text
    if st ~= "on" then
        text = T("The service is not ready or not started.\n\n"
                  .. "Please install the KUAL extension and have its core program in place first, "
                  .. "then come back and tap Start; see \"Status / IP / About\" for the dependency address and current status.",
                 "服务尚未就绪或未启动。\n\n请先安装 KUAL 扩展包并让核心程序就位，\n再回来点「启动」；依附项目地址与当前状态见「状态 / IP / 关于」。")
    elseif ip == "" or ip == "Offline" or ip:find("FB_ERR") then
        text = T("Web File Browser has started, but there is no network connection now.\n"
                  .. "It will pop up the device IP automatically once Wi-Fi is connected.",
                 "网页文件管理器已启动，但当前未联网。\n连上 WiFi 后会自动弹出本机 IP 提示。")
        -- 离线时启动恢复监听：联网后自动居中提示当前 IP
        self:_maybeWatchNetwork()
    else
        text = T("Web File Browser has started\n\nCurrent IP: http://", "网页文件管理器已启动\n\n当前IP：http://") .. ip
    end
    if prefix then
        text = prefix .. "\n\n" .. text
    end
    UIManager:show(InfoMessage:new{ text = text, show_icon = false })
end

-- 合并后的「状态 / IP / 关于」：当前状态 + 依赖项目开源地址
function KOFileBrowser:showAbout()
    local st = capture("status")
    local ip = capture("ip")
    local d = capture("dir")
    local state_line
    if st ~= "on" then
        state_line = T("Service: not started", "服务：未启动")
    elseif ip == "" or ip == "Offline" or ip:find("FB_ERR") then
        state_line = T("Service: running, but no network", "服务：运行中，但当前未联网")
    else
        state_line = T("Service: running · Current IP: http://", "服务：运行中　当前IP：http://") .. ip
    end

    local text = table.concat({
        T("Web File Browser 2 · KOReader Shortcut v", "网页文件管理器 2 · KOReader 快捷方式 v") .. PLUGIN_VERSION,
        "",
        T("Current Status", "当前状态"),
        state_line,
        T("KUAL extension dir: ", "KUAL 扩展目录：")
            .. (d ~= "" and d or T("not found (set FB_HOME at the top of fb_bridge.sh)",
                                   "未找到（可在 fb_bridge.sh 顶部设 FB_HOME）")),
        "",
        T("Dependency", "依赖项目"),
        T("Install the KUAL extension \"Web File Browser 2\" first (it provides the core program)",
          "需先安装 KUAL 扩展包「网页文件管理器 2」（提供核心程序）"),
        "   " .. URL_KUAL_EXT,
    }, "\n")

    if TextViewer then
        UIManager:show(TextViewer:new{
            title = T("Web File Browser 2 · Status / IP / About", "网页文件管理器 2 · 状态 / IP / 关于"),
            text = text,
        })
    else
        -- 老版本无 TextViewer：退化为普通弹窗，内容一致（可能需滚动查看）
        UIManager:show(InfoMessage:new{ text = text, show_icon = false })
    end
end

-- Dispatcher 事件入口（可绑到手势 / 物理按键 / 快捷面板）
function KOFileBrowser:onKOFBStart()   self:onFBStart()   end
function KOFileBrowser:onKOFBStop()    self:onFBStop()    end
function KOFileBrowser:onKOFBShowIP()  self:showInfo(nil) end

-- v1.1.4 息屏卡死根因修复 —— 本次核心：
-- crash.log 铁证：两次强制重启都发生在「服务运行中、等待自动关闭、用户息屏」时，且日志结尾
-- 没有 Tearing down / lipc-wait-event exited normally（正常退出/重启都有），即卡在 suspend
-- 电源关键路径、被迫按电源键硬重启；而 12:33:26 那次 onSuspend service was off、未走 stop
-- 分支，就正常 suspend 并在 16:34 恢复 —— 唯一变量就是「服务在跑时 onSuspend 做了什么」。
-- 根因：Suspend 事件由 broadcastEvent 同步调用各 widget 的 onSuspend（随后系统立刻进入
-- suspend）。旧版在服务运行时于这条关键路径里：
--   ① capture("status") / capture("stop") —— 两次同步 io.popen fork sh 子进程；
--   ② stop 内 lipc-set-prop com.lab126.powerd preventScreenSaver 0 —— 在 powerd 正主导息屏时
--      写它的屏幕保护属性，与其状态机竞争；
--   ③ _clearAwake() 再 spawn("sleep") —— 又一次 LIPC 写。
-- 在进程即将被内核冻结的时刻同步 fork 并等子进程，子进程可能永远得不到调度，UI 线程卡死在
-- io.popen 的 read，系统停在 suspend 中途 → 只能电源键硬重启。
-- 修复：onSuspend 只做纯内存状态操作 —— 零 fork、零 LIPC、零阻塞；服务状态复查、看护恢复
-- 全部推迟到 onResume 之后（已离开电源关键路径）异步执行。suspend 期间不主动停服务：
-- 系统冻结后进程不耗电，resume 后原样恢复，反而避免了反复启停 fork 本身带来的卡顿。
function KOFileBrowser:onSuspend()
    -- 仅内存操作，绝不调用 capture()/spawn()/lipc。
    self._resume_gen = (self._resume_gen or 0) + 1
    -- 保守置位：resume 后复查 status 再决定，避免在此 fork 查询。
    self._resume_restart = true
    self._wd = false
    self._net_watch = false
    klog("onSuspend: memory-only, no shell/powerd, gen =", self._resume_gen)
end

-- 解锁 / 恢复后：延迟到电源关键路径之外，再复查状态、恢复看护。
-- 防抖逻辑（v1.1.1 沿用）：suspend/resume 震荡时每次挂起都会自增 _resume_gen，之前排队的回调
-- 因代际不符而作废；只有设备稳定解锁（这段延迟内未再次挂起）才执行，避免震荡期反复 fork。
function KOFileBrowser:onResume()
    if not self._resume_restart then
        klog("onResume: no pending restart, skip")
        return
    end
    self._resume_restart = false
    local gen = self._resume_gen or 0
    klog("onResume: deferred check queued, gen =", gen)
    -- 延迟约 15 秒：覆盖 crash 日志里 2~6 秒的 suspend/resume 震荡周期；期间再次挂起则本回调作废。
    UIManager:scheduleIn(WD_INTERVAL + 5, function()
        if gen ~= self._resume_gen then
            klog("onResume: deferred check cancelled (generation changed, oscillation)")
            return
        end
        -- 此处已远离电源关键路径；v1.1.6 起不再写任何常亮标记（stop 内已兜底清 0）。
        local st = capture("status")
        if st ~= "on" then
            klog("onResume: service off, no watchdog")
            return
        end
        klog("onResume: service on, restore watchdog")
        self:_startWatchdog()
    end)
end

return KOFileBrowser
