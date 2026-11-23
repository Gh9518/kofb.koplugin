# 网页文件管理器 2 · KOReader 快捷方式（kofb.koplugin）
# Web File Browser 2 · KOReader Shortcut (kofb.koplugin)

> 在 KOReader 里一键**启动 / 关闭** Kindle 上的「网页文件管理器 2」，方便用浏览器无线**传书、管理文件**——而且**全程不用退出 KOReader**。
>
> Start or stop Kindle's "Web File Browser 2" from inside KOReader with one tap, then transfer books and manage files wirelessly from any browser — **without ever leaving KOReader**.

> 应用内界面文字按 KOReader 的系统语言显示：**中文系统显示中文，其它（含英文）显示英文**。
>
> The in-app UI text follows KOReader's system language: **Chinese on zh locales, English otherwise**.

---

## 它解决什么 / What it does

- **方便传输 / Easy transfer**：启动后，在同一 WiFi 下用电脑 / 手机浏览器打开 `http://<本机IP>`，就能像网盘一样上传、下载、管理 Kindle 里的文件，无需数据线。
  Easy transfer: once running, open `http://<device-IP>` in any browser on the same Wi-Fi to upload, download and manage files on the Kindle like a network drive — no USB cable needed.
- **不用退出 KOReader / Stay in KOReader**：启动与关闭都在 KOReader 内完成，KOReader 始终在前台。**不会退回 Kindle 桌面，也不会改写屏幕帧缓冲**（避免在 KOReader 界面上花屏）。
  Both start and stop happen inside KOReader; KOReader stays in the foreground. It never drops to the Kindle home screen and never writes to the framebuffer (so no flicker over the KOReader UI).
- **不另装一套 filebrowser / No separate FileBrowser install**：市面上有些插件会在设备上**再运行一份自己的 filebrowser 程序**；本插件**不重复安装任何核心程序**，而是直接复用你已经装好的 KUAL 扩展包「网页文件管理器 2」里的 filebrowser 二进制。
  Some plugins run their own copy of FileBrowser on the device; this plugin installs nothing extra and simply reuses the `filebrowser` binary already provided by the KUAL extension "Web File Browser 2".
- **⚠️ 依赖前提（务必先读）/ Dependency required (read first)**：本插件**只是快捷方式，本身不含核心程序**。使用前必须先在 Kindle 上装好 KUAL 扩展包「网页文件管理器 2」并让核心程序就位（见下方「依赖」）。未满足依赖时点「启动」会明确提示如何补齐，而不是静默失败。
  This plugin is **only a shortcut — it contains no core program**. You must first install the KUAL extension "Web File Browser 2" and have its core program in place (see "Dependencies" below). If the dependency is missing, tapping **Start** tells you exactly how to install it instead of failing silently.

---

## 依赖 / Dependencies

- 需先安装 KUAL 扩展包 **「网页文件管理器 2」**（提供核心程序 filebrowser）：
  Install the KUAL extension **"Web File Browser 2"** first (it provides the `filebrowser` core program):
  - 开源地址 / Source: <https://github.com/Gh9518/kindle-filebrowser-optimized>

> 能进入 KOReader 的用户，KUAL 启动器与 KOReader 本身通常已就绪；唯一额外要装的就是上面的扩展包，本插件不捆绑、不下载、不运行额外的 filebrowser。
> If you can already open KOReader, the KUAL launcher and KOReader itself are already in place — the only extra thing to install is the extension above. This plugin does **not** bundle, download, or run an extra FileBrowser.

---

## 安装 / Install

1. 在 Release 中下载 `kofb.koplugin.zip`，解压得到 `kofb.koplugin/` 文件夹。
   Download `kofb.koplugin.zip` from the Releases page and extract it to get the `kofb.koplugin/` folder.
2. 把 `kofb.koplugin/` 整个复制到 KOReader 的插件目录：
   Copy the whole `kofb.koplugin/` folder into KOReader's plugins directory:
   - `koreader/plugins/kofb.koplugin/`
3. 重启 KOReader。
   Restart KOReader.

---

## 使用 / Usage

- KOReader 菜单「**工具**」→「**网页文件管理器 2**」：
  KOReader menu **Tools** → **Web File Browser 2**:
  - **启动 / Start**：后台拉起服务（KOReader 保持前台）。菜单项右侧实时显示本机 IP；已运行时再点会直接居中显示当前 IP。
    Launches the service in the background (KOReader stays in front). The device IP shows live on the right of the menu item; tapping again while running shows the current IP centered.
  - **关闭 / Stop**：停止服务，仅提示是否成功。
    Stops the service and reports success or failure.
  - **状态 / IP / 关于 / Status / IP / About**：查看运行状态、本机 IP，以及依赖项目的开源地址。
    Shows the runtime state, the device IP, and the upstream project links.
- 也可在「设置 → 手势 / 物理按键 / 快捷面板」把「启动 / 关闭 / 状态·IP」绑定到你喜欢的操作方式（Dispatcher）。
  You can also bind **Start / Stop / Status·IP** to gestures, hardware keys, or the quick panel via KOReader's Dispatcher.

- **自动关闭（省电 / 不占后台）**：服务启动后，若**连续约 2 分钟无网络**，或**连续约 5 分钟无数据传输**，会自动关闭并居中提示；重新打开即可。看护由 KOReader 前台调度，服务停止即退出，不影响阅读。
  **Auto-close (power-saving):** once running, if there is **no network for ~2 minutes**, or **no data transfer for ~5 minutes**, the service auto-closes with a centered notice; just open it again to restart. The watcher runs on KOReader's foreground scheduler and exits as soon as the service stops.
- **判定精准（v1.1.3 修复）**：「有无数据传输」按 **iptables 中本服务 80 端口的双向累计字节**（内核层）判定——既只统计访问本服务的流量（其他插件如 Storefront 后台抓目录、系统联网都不会误触发「有传输」），又能如实统计 filebrowser 走 **sendfile 零拷贝**的下载/上传。双向统计 **入站 dpt:80（请求/上传）+ 出站 spt:80（下载响应）**，杜绝「正在下载却因只看入站/进程 IO 被判无传输、5 分钟误关」。因此**无数据 5 分钟 reliably 自动关闭**，传输全程不被误断，屏幕也不会被虚假流量一直点亮锁不住屏。
  **Precise activity detection (fixed in v1.1.3):** "data transfer" is judged from the **kernel-level iptables byte counters on this service's port 80** — only traffic to/from this service counts (other plugins like Storefront fetching catalogs, or system networking, can't be mistaken for activity), while downloads/uploads via filebrowser's **sendfile zero-copy** are still counted correctly. Both directions are tracked — **inbound dpt:80 (requests/uploads) + outbound spt:80 (download responses)** — so an in-progress download is never misjudged as idle and closed after 5 minutes. This keeps the **5-minute idle auto-close reliable** without ever cutting off a real transfer.

- **锁屏完全交还系统 / 可正常息屏省电（v1.1.6 根治锁屏震荡卡死）**：crash.log 证实服务运行期曾密集出现 suspend/resume 震荡，而服务关闭后震荡消失——元凶是旧版「活动常亮」写 powerd `preventScreenSaver`：传输时置 1 顶住挂起，且 v1.1.4 把释放推迟到解锁后，若某次挂起未走到解锁则标记永久残留，表现为「锁屏后解锁不了、需按电源键硬重启」。本版**彻底移除常亮机制：插件不再写 preventScreenSaver**，屏幕唤醒/息屏 **100% 交给 KOReader 与系统**，从根源消除锁屏震荡与卡死；传输保活依赖 KOReader 默认息屏策略（前台操作时通常不息屏，影响很小）。
  **Screen fully back to the system / normal sleep & power saving (v1.1.6 lock-freeze fix):** crash.log shows dense suspend/resume oscillation only while the service was running, and none after it stopped — caused by the old "activity wake" writing powerd's `preventScreenSaver`: set to 1 during transfer (blocking suspend), with v1.1.4 deferring the release to unlock, so a suspend that never reached unlock left the flag stuck ("can't unlock after locking", hard reboot required). This version **removes the wake mechanism entirely: the plugin never writes preventScreenSaver**; waking/sleeping is **100% handled by KOReader and the system**, eradicating lock oscillation and freezes. Transfer keep-awake relies on KOReader's default policy (usually no sleep while you're active in the foreground).

- **锁屏零阻塞 / 解锁自动恢复（v1.1.4 息屏卡死根治）**：锁屏（系统挂起）时插件**只改内存状态，绝不 fork 子进程、绝不写 powerd 的 preventScreenSaver**——因为 KOReader 在广播 Suspend 后会立即让系统进入挂起，此刻同步 `io.popen` fork shell 或对 powerd 做 LIPC 写会与系统息屏流程竞争、卡死在挂起中途，只能按电源键硬重启（正是 crash.log 中「服务运行中息屏、日志无退出记录」两次卡死的根因）。服务进程在挂起冻结期间不耗电，解锁稳定后才在电源关键路径之外复查状态、恢复看护。
  **Zero-block on lock / auto-resume on unlock (v1.1.4 freeze fix):** on suspend, the plugin **only updates in-memory state — it never forks a subprocess and never writes powerd's preventScreenSaver**. KOReader suspends the system right after broadcasting `Suspend`; a synchronous `io.popen` fork or an LIPC write to powerd at that instant races with the system's sleep flow and freezes mid-suspend, forcing a hard reboot via the power button (exactly the two "locked while running, no exit record" crashes in crash.log). The frozen service uses no power; only after a stable unlock, outside the power-critical path, does the plugin recheck status and restore the watcher.
- **异步探针 / 主线程零阻塞（v1.1.5 卡屏根治）**：自动关闭看护与网络监听这类高频轮询，改为「后台探针写缓存 + 主线程只读缓存」——把含 iptables 全表遍历、`ifconfig`×4、`ps` 的重量级探测挪到独立后台进程，主线程每轮仅读一个小文本文件，零 fork、零阻塞。crash.log 中 aat 心跳（每 2 秒）曾戛然而止、恰好停在看护恢复之后，正是同步 `io.popen` 等待探针拖住 UI 线程所致；本次彻底消除。菜单/启动等用户主动的低频查询仍用同步探针，保证即时性。
  **Async probe / zero main-thread blocking (v1.1.5 screen-freeze fix):** the high-frequency auto-close watcher and network watcher now use "background probe writes cache, main thread only reads cache" — the heavy probe (full iptables table walk, `ifconfig`×4, `ps`) runs in a separate background process, while the main thread each round only reads a small text file: zero fork, zero blocking. The aat heartbeat (every 2s) in crash.log once stopped dead right after the watcher restored — caused by the synchronous `io.popen` probe stalling the UI thread; now fully resolved. Low-frequency user-triggered lookups (menu / start) still use the synchronous probe for immediacy.
- **震荡防抖（v1.1.1）**：若设备出现 suspend/resume 快速反复（日志中可见数秒内多次挂起/唤醒），插件用代际令牌让挂起前排队的「解锁重启」回调作废，只有**稳定解锁后**才恢复服务——震荡窗口内不再反复启停、反复 fork 进程，降低低内存设备锁屏卡顿的概率。
  **Oscillation debounce (v1.1.1):** if the device rapidly oscillates suspend/resume (visible as repeated suspend/wake within seconds in logs), a generation token invalidates the queued "restart on unlock" callbacks from before suspension, restoring the service only after a **stable unlock** — no repeated start/stop or process forking during the oscillation window, reducing lock-screen stutter on low-memory devices.

---

## 与其它 filebrowser 类插件的区别 / How it differs from other FileBrowser plugins

| | 本插件 kofb / This plugin | 另装一套 filebrowser 的插件 / Plugins that install their own |
|---|---|---|
| 核心程序 / Core program | **复用** KUAL 扩展包的 filebrowser / **Reuses** the KUAL extension's filebrowser | 各自再装一份 / Each installs its own |
| 退出 KOReader / Leaving KOReader | **不需要** / **Not required** | 视实现而定 / Depends on the plugin |
| 额外占用 / Extra footprint | 仅一个快捷方式 / Just a shortcut | 多一份程序与空间 / An extra program and storage |

---

## 关于页与开源地址 / About page & source links

- KUAL 扩展包「网页文件管理器 2」/ KUAL extension "Web File Browser 2": <https://github.com/Gh9518/kindle-filebrowser-optimized>

---

## 卸载 / Uninstall

删除 `koreader/plugins/kofb.koplugin/` 并重启 KOReader 即可。本插件不改动 KOReader 本体，也不改动 KUAL 插件包。
Delete `koreader/plugins/kofb.koplugin/` and restart KOReader. This plugin does not modify KOReader itself or the KUAL extension package.

---

## 原理简述 / How it works

本插件自带 `fb_bridge.sh` 桥接脚本，只做两件事：**放行 80 端口 / 后台拉起已有的 filebrowser 二进制**，并复用 KUAL 扩展包里的核心程序与数据库。它**不回桌面、不写 eips、不碰无线开关、不拉起会写屏的守护、不写屏幕常亮标记**，因此与 KOReader 前台运行完全解耦——KUAL 包后续升级也不会破坏本插件。v1.1.6 起屏幕唤醒/息屏完全交给 KOReader 与系统，插件不再抢占（仅停止服务时做一次清 0 兜底以兼容 KUAL 混合启动）。
The plugin ships a small `fb_bridge.sh` bridge script that only: opens port 80 and launches the existing `filebrowser` binary in the background — reusing the KUAL extension's core program and database. It does **not** return to the home screen, does **not** write to `eips`, does **not** touch the wireless switch, does **not** start the screen-writing watchdog, and **never writes the screen-awake flag**, so it stays fully decoupled from KOReader's foreground and survives future KUAL extension upgrades. Since v1.1.6 waking/sleeping is 100% handled by KOReader and the system (a single clear-to-0 on stop remains only as a safeguard for mixed KUAL launches).

---

## 更新日志 / Changelog

- **v1.1.6**：根治「锁屏后解锁不了、需按电源键硬重启」——crash.log 显示服务运行期（08:48–09:27）密集出现 suspend/resume 震荡（间隔 25s/43s/36s/11s…），服务关闭后震荡消失。元凶是 v1.1.0 引入的「活动常亮」写 powerd `preventScreenSaver`：传输时置 1 顶住挂起，v1.1.4 又把释放推迟到解锁后，若某次挂起未走到解锁则标记永久残留。**彻底移除 wake/sleep 机制**：插件不再写 preventScreenSaver、移除 `wake`/`sleep` 子命令与相关状态/常量，屏幕唤醒/息屏 100% 交还 KOReader 与系统；仅 `stop` 保留一次清 0 兜底（兼容 KUAL 混合启动，属释放、不顶住挂起）。判定与自动关闭逻辑不变。
  **v1.1.6:** fixed "can't unlock after locking, hard reboot required" — crash.log shows dense suspend/resume oscillation while the service ran (08:48–09:27, gaps of 25s/43s/36s/11s…) that vanished after it stopped. Culprit: the v1.1.0 "activity wake" writing powerd's `preventScreenSaver` (set to 1 during transfer, blocking suspend) with v1.1.4 deferring release to unlock, so a suspend that never reached unlock left it stuck. **Removed the wake/sleep mechanism entirely**: the plugin no longer writes preventScreenSaver, dropping the `wake`/`sleep` subcommands and related state/constants; waking/sleeping is 100% back to KOReader and the system. Only `stop` keeps one clear-to-0 safeguard (for mixed KUAL launches; a release, not a block). Detection and auto-close logic unchanged.
- **v1.1.5**：根治「看护轮询拖住 UI 线程导致的卡屏」——结合两份 crash.log 与 aat 每 2 秒心跳定位：一次卡屏时事件循环停摆、恰在看护恢复之后。根因是自动关闭看护（每 10 秒）与网络监听（每 3 秒）在主线程同步 `io.popen("sh fb_bridge.sh probe")`，而 probe 含 iptables 全表遍历、`ifconfig`×4、`ps`，低内存 PW4 上叠加 Storefront 后台联网时会长时间阻塞 UI。改为后台 `probe_file` 子命令把三态原子写入缓存文件、主线程只读缓存（零 fork / 零阻塞），缓存缺失时首轮回退一次同步探针；菜单/启动等低频即时查询仍用同步 probe。桥接脚本新增 `probe_file`，输出格式与 `probe` 完全一致，判定逻辑不变。
  **v1.1.5:** fixed the "screen freeze caused by the watcher stalling the UI thread" — two crash logs plus the aat 2-second heartbeat pinpointed it: the event loop stalled right after the watcher restored. Root cause: the auto-close watcher (every 10s) and network watcher (every 3s) synchronously `io.popen("sh fb_bridge.sh probe")` on the main thread, and probe does a full iptables walk, `ifconfig`×4 and `ps` — on a low-memory PW4 with Storefront fetching in the background this blocks the UI for a long time. Now a background `probe_file` subcommand atomically writes the three-state result to a cache file and the main thread only reads the cache (zero fork / zero blocking), with a one-time synchronous fallback if the cache is missing; low-frequency user-triggered lookups still use the synchronous probe. The bridge adds `probe_file` with output identical to `probe`; detection logic is unchanged.
- **v1.1.4**：根治「服务运行中息屏导致的卡死、需按电源键硬重启」——crash.log 显示两次强制重启都发生在等待自动关闭期间息屏、且日志无任何退出记录；根因是 `onSuspend` 在 suspend 电源关键路径中同步 `io.popen` fork shell 并对 powerd 的 `preventScreenSaver` 做 LIPC 写，与系统息屏流程竞争而挂死。改为挂起时只改内存状态、零 fork / 零 LIPC，状态复查与看护恢复全部延迟到解锁后（电源路径之外）执行。另将无传输关闭提示精简为「长时间无数据传输，已关闭网页文件管理器」，去掉易误解的具体分钟数。
  **v1.1.4:** fixed the "freeze when locking the screen while the service runs, requiring a hard reboot" — crash.log showed both forced reboots happened while locking during the auto-close wait, with no exit record at all. Root cause: `onSuspend` synchronously `io.popen`-forked a shell and did an LIPC write to powerd's `preventScreenSaver` inside the suspend power-critical path, racing with the system's sleep flow and hanging. It now only touches in-memory state on suspend — zero fork / zero LIPC — deferring status rechecks and watcher restoration until after unlock (outside the power path). The idle-close notice is also simplified to "Web File Browser closed after a period of inactivity", dropping the potentially misleading minute count.
- **v1.1.3**：修复「正在传输却被判无传输、5 分钟误关」——v1.1.1 改用的进程 IO 对 Go HTTP 服务的 `sendfile` 零拷贝无效（下载/上传不经用户态 read/write），判定源改回内核层 **iptables 80 端口双向累计字节**：只统计访问本服务的流量（剔除其它程序联网），sendfile 同样计数；并新增出站 `spt:80`，使纯下载（出站流量）不再被漏判。两端（KOReader 快捷方式 + KUAL 包）判定源同步修复，一次 `iptables -L` 取双向、仅 1 次 fork。
  **v1.1.3:** fixed "real transfer misjudged as idle and closed after 5 min" — the process IO used since v1.1.1 is blind to Go's `sendfile` zero-copy (downloads/uploads bypass userspace read/write). Detection now uses **kernel-level iptables bidirectional byte counters on port 80**: only this service's traffic counts (other apps excluded), sendfile is counted, and an outbound `spt:80` counter was added so download-only traffic is no longer missed. Both sides (KOReader shortcut + KUAL package) fixed in sync; one `iptables -L` reads both directions, single fork.
- **v1.1.2**：为关键事件（加载 / 启停 / 自动关闭 / 挂起恢复 / 网络恢复）增加结构化日志，统一 `kofb:` 前缀，可在 KOReader 的 `crash.log` 中 `grep kofb:` 快速定位插件行为；仅在离散事件记录，轮询热路径不打日志，不增加低内存设备负担。
  **v1.1.2:** added structured logs for key events (load / start-stop / auto-close / suspend-resume / network recovery), all prefixed `kofb:` so they can be grepped from KOReader's `crash.log`; discrete events only — the polling hot path stays silent, no extra cost on low-memory devices.
- **v1.1.1**：修复"长时间无传输不自动关闭"与"锁不住屏"——根因是活动判定用了整机网卡流量、被其它程序的联网污染；改为只统计 filebrowser 进程自身 IO。挂起/恢复加入代际令牌防抖，避免 suspend/resume 震荡窗口内反复启停。
  **v1.1.1:** fixed "no idle auto-close" and "screen won't lock" — both caused by judging activity from total NIC traffic polluted by other apps; now uses the filebrowser process's own IO. Added generation-token debounce across suspend/resume to avoid repeated start-stop during oscillation.
- **v1.1.0**：移除"启动即常亮"，改为活动感知常亮（仅在传输时短暂保持唤醒，停传约 1 分钟即释放），设备可正常息屏省电。
  **v1.1.0:** replaced always-on wake with activity-based wake (awake only during transfer, released ~1 min after), so the device can sleep normally.
- **v1.0.9**：修复锁屏卡死——挂起前自动停服务并释放常亮标记，解锁后自动恢复；轮询合并为单次 `probe`，降低进程开销。
  **v1.0.9:** fixed lock-screen freeze — stop service and release wake flag before suspend, auto-restore on unlock; merged polling into a single `probe` to cut process overhead.
- **v1.0.8**：新增自动关闭看护（无网络约 2 分钟 / 无传输约 5 分钟）。
  **v1.0.8:** added auto-close watchdog (~2 min offline / ~5 min idle).
- **v1.0.7**：新增网络恢复自动提示——离线后连上 WiFi 自动居中弹出本机 IP。
  **v1.0.7:** added network-recovery notice — auto-popup the IP when Wi-Fi returns after being offline.
- **v1.0.6**：界面文案中英双语，按 KOReader 系统语言自动切换。
  **v1.0.6:** bilingual UI text that follows KOReader's system language.
- **v1.0.5**：启动/关闭/状态提示统一居中并精简，启动成功提示去掉冗余端口。
  **v1.0.5:** centered and simplified start/stop/status notices; dropped the redundant port from the success message.

---

当前版本 / Current version: **1.1.6**。
