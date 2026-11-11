# 网页文件管理器 2 · KOReader 快捷方式（kofb.koplugin）

> 在 KOReader 里一键**启动 / 关闭** Kindle 上的「网页文件管理器 2」，方便用浏览器无线**传书、管理文件**——而且**全程不用退出 KOReader**。

---

## 它解决什么 / Why

- **方便传输**：启动后，在同一 WiFi 下用电脑 / 手机浏览器打开 `http://<本机IP>`，就能像网盘一样上传、下载、管理 Kindle 里的文件，无需数据线。
- **不用退出 KOReader**：启动与关闭都在 KOReader 内完成，KOReader 始终在前台。**不会退回 Kindle 桌面，也不会改写屏幕帧缓冲**（避免在 KOReader 界面上花屏）。
- **不另装一套 filebrowser**：市面上有些插件会在设备上**再运行一份自己的 filebrowser 程序**；本插件**不重复安装任何核心程序**，而是直接复用你已经装好的 KUAL 扩展包「网页文件管理器 2」里的 filebrowser 二进制。
- **⚠️ 依赖前提（务必先读）**：本插件**只是快捷方式，本身不含核心程序**。使用前必须先在 Kindle 上装好 KUAL 扩展包「网页文件管理器 2」并让核心程序就位（见下方「依赖」）。未满足依赖时点「启动」会明确提示如何补齐，而不是静默失败。

---

## 依赖 / Prerequisites（前提条件）

1. 已越狱，并安装 **KUAL** 启动器。
2. 已安装 KUAL 扩展包 **「网页文件管理器 2」**（提供核心程序 filebrowser）：
   - 开源地址：<https://github.com/Gh9518/kindle-filebrowser-optimized>
3. 已安装 **KOReader**（本插件运行在 KOReader 内部）。

> 本插件**不捆绑、不下载、不运行**额外的 filebrowser，所有核心能力都来自上面的 KUAL 扩展包。

---

## 安装 / Install

1. 在 Release 中下载 `kofb.koplugin.zip`，解压得到 `kofb.koplugin/` 文件夹。
2. 把 `kofb.koplugin/` 整个复制到 KOReader 的插件目录：
   - `koreader/plugins/kofb.koplugin/`
3. 重启 KOReader。

---

## 使用 / Usage

- KOReader 菜单「**工具**」→「**网页文件管理器 2**」：
  - **启动**：后台拉起服务（KOReader 保持前台）。菜单项右侧实时显示本机 IP；已运行时再点会直接居中显示当前 IP。
  - **关闭**：停止服务，仅提示是否成功。
  - **状态 / IP / 关于**：查看运行状态、本机 IP，以及依赖项目的开源地址。
- 也可在「设置 → 手势 / 物理按键 / 快捷面板」把「启动 / 关闭 / 状态·IP」绑定到你喜欢的操作方式（Dispatcher）。

---

## 与其它 filebrowser 类插件的区别

| | 本插件 kofb | 另装一套 filebrowser 的插件 |
|---|---|---|
| 核心程序 | **复用** KUAL 扩展包的 filebrowser | 各自再装一份 |
| 退出 KOReader | **不需要** | 视实现而定 |
| 额外占用 | 仅一个快捷方式 | 多一份程序与空间 |

---

## 关于页与开源地址

- KUAL 扩展包「网页文件管理器 2」：<https://github.com/Gh9518/kindle-filebrowser-optimized>
- 核心程序 filebrowser：<https://github.com/filebrowser/filebrowser>
- KUAL 启动器：<https://github.com/NiLuJe/KUAL>
- KOReader：<https://github.com/koreader/koreader>

---

## 卸载 / Uninstall

删除 `koreader/plugins/kofb.koplugin/` 并重启 KOReader 即可。本插件不改动 KOReader 本体，也不改动 KUAL 插件包。

---

## 原理简述 / How it works

本插件自带 `fb_bridge.sh` 桥接脚本，只做三件事：**防休眠 / 放行 80 端口 / 后台拉起已有的 filebrowser 二进制**，并复用 KUAL 扩展包里的核心程序与数据库。它**不回桌面、不写 eips、不碰无线开关、不拉起会写屏的守护**，因此与 KOReader 前台运行完全解耦——KUAL 包后续升级也不会破坏本插件。

---

当前版本：**1.0.5**。
