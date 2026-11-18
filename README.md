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
- **判定精准（v1.1.1 修复）**：「有无数据传输」只按 **filebrowser 进程自身的 IO** 判定，不再看整机网卡流量——因此其他插件（如 Storefront 后台抓目录）或系统联网都不会误触发「有传输」，既保证**无数据 5 分钟 reliably 自动关闭**，也避免屏幕被虚假流量一直点亮锁不住屏。
  **Precise activity detection (fixed in v1.1.1):** "data transfer" is judged only from the **filebrowser process's own IO**, not total network traffic — so other plugins (e.g. Storefront fetching catalogs) or system networking can no longer be mistaken for activity. This keeps the **5-minute idle auto-close reliable** and prevents the screen from being kept awake by phantom traffic.

- **活动感知常亮 / 可正常息屏省电（v1.1.0）**：启动后**不再全程保持屏幕常亮**。仅在**确实有数据传输时**才短暂置起「屏幕常亮」标记以保证传输不中断；停传约 **1 分钟**即自动释放，设备随即可以正常息屏休眠、省电。屏幕唤醒平时完全交给 KOReader 自己管理，插件不抢占。
  **Activity-based wake / normal sleep & power saving (v1.1.0):** the screen is **no longer kept awake for the whole session**. The "keep awake" flag is set **only while data is actually transferring**, so the transfer is never interrupted; about **1 minute** after transfer stops it is released and the device can sleep normally to save power. Screen waking is otherwise left entirely to KOReader — the plugin does not grab that global flag.

- **锁屏自动停 / 解锁自动恢复（修复锁屏卡死）**：锁屏（系统挂起）前自动关闭服务并兜底释放「屏幕常亮」标记——该标记若在挂起时仍被持有会顶住系统挂起流程、造成反复震荡直至卡死；同时释放 filebrowser 占用的内存。解锁后若锁屏前服务在运行会自动重新拉起，传输无缝继续。
  **Auto-stop on lock / auto-resume on unlock (fixes lock-screen freeze):** before the system suspends, the service is stopped and the "keep awake" flag cleared as a safeguard — holding that flag during suspend stalls the suspend flow and freezes the device. The filebrowser process (and its memory) is freed while asleep. If it was running before you locked, it restarts automatically on unlock.
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

本插件自带 `fb_bridge.sh` 桥接脚本，只做三件事：**放行 80 端口 / 后台拉起已有的 filebrowser 二进制 / 按活动情况短暂置放屏幕常亮标记**，并复用 KUAL 扩展包里的核心程序与数据库。它**不回桌面、不写 eips、不碰无线开关、不拉起会写屏的守护**，因此与 KOReader 前台运行完全解耦——KUAL 包后续升级也不会破坏本插件。屏幕唤醒不再全程抢占：仅传输期间短暂置起、停传约 1 分钟即释放，让设备能正常息屏省电。
The plugin ships a small `fb_bridge.sh` bridge script that only: opens port 80, launches the existing `filebrowser` binary in the background, and toggles the screen-awake flag based on transfer activity — reusing the KUAL extension's core program and database. It does **not** return to the home screen, does **not** write to `eips`, does **not** touch the wireless switch, and does **not** start the screen-writing watchdog, so it stays fully decoupled from KOReader's foreground and survives future KUAL extension upgrades. Screen waking is no longer grabbed for the whole session: it is set only during transfers and released about 1 minute after transfer stops, letting the device sleep normally to save power.

---

当前版本 / Current version: **1.1.1**。
