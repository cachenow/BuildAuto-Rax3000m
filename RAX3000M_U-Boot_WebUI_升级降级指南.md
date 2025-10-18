# RAX3000M U-Boot WebUI 升级/降级指南（NAND/eMMC）

面向 CMCC RAX3000M 的 eMMC（算力版）与 NAND（普通版），本指南提供“仅通过 U-Boot WebUI”完成从支持 BIN 的 U-Boot 切换到支持 ITB（FIT）的 U-Boot，或反向降级回支持 BIN 的 U-Boot，并最终通过 WebUI 刷入系统固件（`.bin` 或 `.itb`）。

指南要点：
- U-Boot WebUI 变种通常提供专用页面：`gpt.html`（GPT）、`bl2.html`（Preloader/BL2）、`uboot.html`（FIP/U‑Boot 本体），以及固件上传页面（接受 `.bin` 或 `.itb`）。
- 官方 OpenWrt/ImmortalWrt 提供的 `bl31-uboot.fip` 不包含 HTTP/WebUI；hanwckf 的 `bl-mt798x` 变体（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）包含 WebUI，可在 `http://192.168.1.1/` 或 `http://192.168.1.1/uboot.html` 访问。
- 选择“ITB 路线”或“BIN 路线”时，必须对应刷入匹配的 GPT/BL2/FIP 套件；完成后，固件页面才会接受你想要的格式。
- 在“具备 WebUI”这一前提下可全程通过浏览器完成；若当前是官方 U‑Boot（无 WebUI），请先按“新机原厂固件→稳定 U‑Boot”章节通过串口/TFTP或系统内（仅 NAND）替换为带 WebUI 的 hanwckf FIP，再继续本文的 WebUI 流程。

新手阅读顺序（建议 5 步）：
- 识别设备介质（eMMC 或 NAND）。
- 打开“选择你的设备（新用户快速入口）”，按设备选择 ITB 或 BIN 路线。
- 进入对应设备章节的“下载与文件清单（速查）”，按文件名核对并下载。
- 执行“新机入手（从 0 到首刷）”，完成首次固件写入。
- 如需切换版本，按“24.10 ⇄ 23.05”的降级/升级流程继续。

—

## 识别设备与进入 WebUI
- 设备介质识别：
  - 标签“CH EC …”→ eMMC；标签“CH …”→ NAND。
  - 若已能进入系统，也可用 `df -h` 查看是否有 ~56GB 数据盘（eMMC）。
- 进入 WebUI：
  - 复位进入 U‑Boot；新版 U‑Boot 通常支持 DHCP，电脑保持自动获取；若不支持则将电脑设静态 `IP 192.168.1.2 / 网关 192.168.1.1`。
  - 在浏览器访问 `http://192.168.1.1/`，或直接进入：
    - `http://192.168.1.1/gpt.html`（刷 GPT）
    - `http://192.168.1.1/bl2.html`（刷 BL2/Preloader）
    - `http://192.168.1.1/uboot.html`（刷 FIP/U‑Boot）
    - 固件上传页面（不同变种命名略有差异，通常在首页或菜单可见）

—

## 选择你的设备（新用户快速入口）

### eMMC（算力版，64GB）快速入口
- 路线选择：
  - ITB（官方 all‑in‑FIT）：固件为 `.itb`。使用 Developer Drive 的 `emmc-fip-fit.bin`（含 DHCP + WebUI）可直接用浏览器首刷；若改用上游官方 `bl31-uboot.fip`（通常不含 WebUI），首刷需走 TFTP。
  - BIN（单分区/自定义）：固件为 `.bin`，配合带 WebUI 的 FIP 通过浏览器首刷。
- 首刷步骤：
  - ITB：使用 Developer Drive 的 `emmc-fip-fit.bin`（含 WebUI）→ 在 WebUI 上传 `initramfs-recovery.itb` → 进入系统 → 升级到 `squashfs-sysupgrade.itb`；若改用上游官方 `bl31-uboot.fip`（无 WebUI），则走 `TFTP`。
  - BIN（WebUI）：`gpt.html → bl2.html → uboot.html → 上传 .bin`（使用 `emmc-gpt.bin / emmc-bl2.bin / emmc-fip.bin` 三件套或社区 WebUI FIP）。
- 下载与文件清单：
  - ITB：`emmc-gpt.bin`、`emmc-preloader.bin`、`emmc-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`。
  - BIN：`emmc-gpt.bin`、`emmc-bl2.bin`、`emmc-fip.bin`（或 hanwckf FIP，含 WebUI），以及与你选择的布局匹配的 BIN 格式固件。
- 详细教程：详见下文“eMMC（算力版，64GB）”章节的 ITB 与 BIN 流程。

### NAND（普通版，128MB）快速入口
- 路线选择：
  - ITB（主线）：官方分区布局与 `.itb` 固件。
  - BIN（uboot/ubootmod）：与当前 UBI 布局匹配的 `.bin` 固件。
- 首刷步骤：
  - ITB：`bl2.html → uboot.html → 上传 initramfs-recovery.itb → 进入系统 → 升级到 squashfs-sysupgrade.itb`（官方 FIP 无 WebUI 时，先替换为带 WebUI 的 FIP 或走 TFTP）。
  - BIN：`uboot.html → 上传 hanwckf FIP（含 WebUI）→ 上传与当前布局匹配的 NAND uboot/ubootmod BIN 固件`。
- 下载与文件清单：
  - ITB：`nand-preloader.bin`、`nand-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`。
  - BIN：`mt7981_cmcc_rax3000m-fip-fixed-parts.bin`、与当前布局匹配的 NAND uboot/ubootmod BIN 固件。
- 详细教程：详见下文“NAND（普通版，128MB）”章节的 ITB 与 BIN 流程。

## 核心概念与术语
- 介质与硬件：RAX3000M 分为 eMMC（算力版）与 NAND（普通版），二者刷机文件不可混用。
- GPT（仅 eMMC）：磁盘分区表，用于 eMMC 的分区布局对齐。
 - BL2/Preloader：早期加载阶段，eMMC 写入到 `mmcblk0boot0`，NAND 使用 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin` 或 `openwrt-23.05.4-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`。
 - FIP（firmware image package）：包含 `bl31 + u-boot` 的容器。官方示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip` 与 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`；Developer Drive 命名：`mt7981-cmcc_rax3000m-emmc-fip.bin`、`mt7981-cmcc_rax3000m-emmc-fip-fit.bin`；hanwckf 命名：`mt7981_cmcc_rax3000m-fip-fixed-parts.bin`。
- Developer Drive（ImmortalWrt 镜像下载站）：域名 `drive.wrt.moe`，承载 U‑Boot 三件套与 FIP 变体；原 `firmware.download.immortalwrt.eu.org` 现已重定向至此。本文所称 `emmc-fip.bin / emmc-fip-fit.bin` 即来源于该站，其中 `emmc-fip-fit.bin` 默认内置 WebUI，便于纯浏览器首刷。
- U‑Boot WebUI：带 HTTP 页面（`http://192.168.1.1`），可直接上传 GPT/BL2/FIP 与固件；Developer Drive 的 `emmc-fip.bin / emmc-fip-fit.bin` 默认内置 WebUI；官方 `bl31-uboot.fip` 通常不含 WebUI。
- 路线选择：
  - ITB（all‑in‑FIT，官方布局）：固件为 `.itb`；eMMC 选 `emmc-fip-fit.bin`；NAND 首选 `mt7981-cmcc_rax3000m-nand-fip-fit.bin`（含 WebUI）。如改用官方 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（通常不含 WebUI），首刷需走 TFTP。
  - BIN（custom layout/单分区）：固件为 `.bin`；eMMC 选 `emmc-fip.bin`（或 hanwckf FIP）；NAND 选 hanwckf FIP。
- 恢复方式：无 WebUI 的官方 FIP 首次刷机使用 TFTP；含 WebUI 的 FIP 可直接通过浏览器上传。
- 关键原则：严禁混刷；`emmc-*` 只用于 eMMC，`nand-*` 只用于 NAND；下载前严格核对文件名与介质。

—

## 下载与项目资源
来源确认（链接与证据）：
 - ImmortalWrt PR #1075 明确 RAX3000M 的 eMMC/NAND 三件套与命令，文件名前缀为 `immortalwrt-<version>-mediatek-filogic-cmcc_rax3000m-`，示例包含 `emmc-gpt.bin`、`emmc-preloader.bin`、`emmc-bl31-uboot.fip`、`initramfs-recovery.itb`、以及 NAND 的 `nand-preloader.bin` 与 `nand-bl31-uboot.fip`（https://github.com/immortalwrt/immortalwrt/pull/1075）。
 - OpenWrt 主线提交同样给出 eMMC/NAND 的三件套与写入命令，文件名前缀为 `openwrt-<version>-mediatek-filogic-`（https://git.openwrt.org/?a=commitdiff&h=423186d7d8b4f23aee91fca4f1774a195eba00d8）。
 - ImmortalWrt 24.10 发布目录索引中列出了 mediatek/filogic 目标的镜像，命名前缀示例为 `immortalwrt-24.10.2-mediatek-filogic-`，对应设备条目中提供 `bl31-uboot.fip`、`preloader.bin`、`gpt.bin`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`（示例入口：https://downloads.immortalwrt.org/releases/24.10.2/targets/mediatek/filogic/）。
- 社区 BIN（WebUI）FIP 的常见来源不止 hanwckf，亦可自编译 MTK/WebUI FIP；hanwckf 发布页提供 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin` 作为示例（https://github.com/hanwckf/bl-mt798x/releases）。
- U‑Boot 三件套（GPT/BL2/FIP）官方镜像库：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`
  - 选择与设备介质匹配的 `cmcc_rax3000m` 的 `emmc` 或 `nand` 版本；注意区分“all‑in‑FIT（ITB 路线）”与“custom U‑Boot layout（单分区，BIN 路线）”。
  - 三件套具体文件（按介质区分）：
    - eMMC：`immortalwrt-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`（GPT）/`immortalwrt-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`（BL2）/`immortalwrt-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`（FIP）
    - NAND：`immortalwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（BL2）/`immortalwrt-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（FIP）（NAND 不使用 GPT 文件）。
  - 23.05 与 24.10 的前缀差异：ImmortalWrt 文件名前缀示例为 `immortalwrt-24.10.0-`；OpenWrt 文件名前缀示例为 `openwrt-23.05.4-`。文件主体名（设备与介质后缀）一致，注意按镜像站选择对应前缀避免误下。
  - 三件套具体文件名（按来源/版本，对照速查）：
    - ImmortalWrt 24.10（eMMC）：
      - `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`
      - `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`
      - `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`
    - ImmortalWrt 23.05（eMMC）：
      - `immortalwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`
      - `immortalwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`
      - `immortalwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`
    - OpenWrt 23.05（eMMC，文件前缀不同）：
      - `openwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`
      - `openwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`
      - `openwrt-23.05.x-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`
    - ImmortalWrt/OpenWrt（NAND）同理：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin` + `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（OpenWrt 23.05.4 前缀同名；NAND 无 GPT 文件）。
    - 说明：`23.05.x` 指小版本号（如 `23.05.4`）；下载页往往把前缀截断显示，但文件名中完整前缀均存在。文件命名与存在性可参照官方提交与发布目录索引［见引用 1、2、3］。
- ImmortalWrt 24.10.0 ITB 固件（官方选择器）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
  - 可下载 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`。
- OpenWrt 主线 ITB 固件（备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`
- eMMC 单分区 BIN 固件（闭源驱动路线）社区构建：
  - `https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`
  - `https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`
- NAND 侧用于恢复 BIN 支持的 FIP（常见变体）：
  - `https://github.com/hanwckf/bl-mt798x/releases`（例如 20231124 版本，包含适配 MT7981 的 FIP 固件）

### 文件名核对与别名对照（来源见引用）
- 官方 U‑Boot（OpenWrt/ImmortalWrt）：
  - eMMC：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`（OpenWrt 23.05.4 前缀同名）
  - NAND：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（OpenWrt 23.05.4 前缀同名）
  - 以上命名与文件存在性，见官方提交与说明：[ImmortalWrt PR #1075](https://github.com/immortalwrt/immortalwrt/pull/1075)；OpenWrt 主线同样使用 `u-boot.fip` 命名，[OpenWrt 提交](http://lists.infradead.org/pipermail/lede-commits/2023-October/019553.html)。
- 官方固件（ITB）：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-squashfs-sysupgrade.itb`（选择器页面可直接下载）。
- 社区 FIP（BIN 路线，含 WebUI）：`mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（hanwckf/bl‑mt798x 发布页），参见 [hanwckf 发布](https://github.com/hanwckf/bl-mt798x/releases)。

备注：部分社区教程/贴子会将支持 FIT 的 FIP 写作 “fip.fit/bin”，这是错误口径。官方统一为 `.fip`；hanwckf 变体以 `.bin` 命名（同为 FIP 容器）。上述对照已在本文统一纠正。

补充（drive 目录的实际命名对照）：
- 目录：`https://drive.wrt.moe/uboot/mediatek/`
- eMMC：`mt7981-cmcc_rax3000m-emmc-gpt.bin`（= GPT）、`mt7981-cmcc_rax3000m-emmc-bl2.bin`（= Preloader/BL2）、`mt7981-cmcc_rax3000m-emmc-fip.bin`（≈ `bl31-uboot.fip`）、`mt7981-cmcc_rax3000m-emmc-fip-fit.bin`（FIT 路线 FIP，含 WebUI）
- NAND：`mt7981-cmcc_rax3000m-nand-fip-stock.bin`（含 WebUI）、`mt7981-cmcc_rax3000m-nand-fip-fit.bin`（FIT 路线 FIP，含 WebUI）、`mt7981-cmcc_rax3000m-nand-fip-expand.bin`（含 WebUI）
- 选择建议：
  - 走 ITB 主线 → 首选 `emmc-fip-fit.bin`（eMMC，含 WebUI）或 `nand-fip-fit.bin`（NAND，含 WebUI），后续刷 `.itb` 固件。
  - 走 BIN/uboot(ubootmod) → eMMC 可配合 `emmc-gpt.bin + emmc-bl2.bin + emmc-fip.bin`（或社区 WebUI FIP），NAND 选 `nand-fip-stock/expand` 等与目标固件布局匹配的 FIP（均含 WebUI）。



### 快速入口（页面直链）
- U‑Boot 三件套目录（GPT/BL2/FIP）：`https://drive.wrt.moe/uboot/mediatek/`（原 `firmware.download.immortalwrt.eu.org/uboot/mediatek/` 已重定向至此）
- ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
- OpenWrt 固件目录（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`
- eMMC BIN 社区构建：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`
- NAND BIN FIP 发布页：`https://github.com/hanwckf/bl-mt798x/releases`

说明：ImmortalWrt 的下载站可能出现人机验证（Cloudflare），请耐心等待或更换浏览器；文件命名随发布版本略有差异，尤其 `drive.wrt.moe` 目录使用 `mt7981-cmcc_rax3000m-*` 前缀，请按本章的命名映射核对后再下载。

—

## 新机原厂固件 → 稳定 U‑Boot（选型与完整步骤）

目的：拿到新机（OEM 出厂系统）时，从零开始选择稳定的 U‑Boot 路线（ITB 或 BIN），并完成从入场、备份到刷写与验证的完整流程。

### 从原厂系统开启 SSH 权限（免拆，NAND/eMMC 通用）
 - 适用：原厂系统后台可导入/导出配置，常见默认管理地址 `http://192.168.10.1/`。
 - 两种方法（任选其一，均为官方文档所述做法的延伸）：
   - 方法 A（配置导入法，免拆）：
     - 导出配置得到 `cfg_export_config_file.conf`。
     - 若配置未加密：直接在 Linux/WSL 下 `tar -zxf cfg_export_config_file.conf` 解包；若加密：用 `openssl aes-256-cbc -d -pbkdf2 -k <密钥> -in cfg_export_config_file.conf -out - | tar -zxvf -` 解包（常见密钥样例见社区贴，批次可能不同）。
     - 编辑 `etc/config/dropbear`：将 `option enable '0'` 改为 `option enable '1'`（开启 SSH）。
     - 编辑 `/etc/shadow`：将 `root` 行的密码哈希清空为 `root::19523:0:99999:7:::`（或去除哈希使其免密）。
     - 重新打包：未加密直接 `tar -zcf cfg_export_config_file.conf etc/`；加密则管道到 `openssl aes-256-cbc -pbkdf2 -k <密钥> -out cfg_export_config_file_new.conf`。
     - 后台导入新配置，设备重启后用 `ssh root@192.168.10.1` 登录；文件传输如遇 `sftp-server: not found`，使用 `scp -O` 参数。
     - 参考来源：OpenWrt/ImmortalWrt 对 RAX3000M 的支持提交包含“获取 SSH”步骤与示例格式（见本文引用）。
   - 方法 B（串口登录，强力可靠）：
     - 连接 3.3V TTL（GND/TX/RX，115200）；引脚布局见官方说明（串口排针通常为 `GND TX VCC RX` 顺序）。
    - 上电后按任意键中断启动，进入 U‑Boot 提示符或 OEM 控制台；如 OEM 未启用 HTTP/WebUI，可直接用串口进行 TFTP 引导或执行刷写命令。
   - 方法 C（UARTBoot 急救，备用）：
     - 在早期引导失败或 BL2/FIP 写错时，可使用 `mtk_uartboot` 直接向设备 RAM 注入恢复镜像，再进入 U‑Boot/TFTP 路线修复；需要稳定的 TTL 连接与独立电源。
 - 完成后建议：修改管理地址与设置管理员密码；启用 `dropbear` 并验证 `ssh` 可用；上传镜像到 `/tmp/` 后进行刷写。

### 配置文件解密密钥参考（批次归类与操作建议）
- 固定密钥（旧批次，需正确引号与转义）：
  - 实际可用密钥为 `'#RaX30O0M@!$'`（必须加引号）。日志中常见的 `$CmDc#RaX30O0M@!$` 为未加引号的记录字符串，其中 `$` 与 `!` 在 shell 中会触发扩展，直接复制会导致解密失败。
  - 典型命令（Linux/WSL）：
    - 解密：`openssl aes-256-cbc -d -pbkdf2 -k '#RaX30O0M@!$' -in cfg_export_config_file.conf -out cfg_export.tar.gz`
    - 再加密：`openssl aes-256-cbc -pbkdf2 -k '#RaX30O0M@!$' -in cfg_modified.tar.gz -out cfg_export_config_file_new.conf`
  - 适用批次与证据：2023‑10/12 及相近旧版（如 20231027）普遍有效；参考社区教程与仓库整理（恩山贴 8316001、8320480；`fanmaomao/CMCC_RAX3000M`；`sh1marin`）。

- SN 派生密钥（新批次，2024‑01/02 及以后为主流）：
  - 新固件开始按设备序列号（SN）派生密码，固定密钥会出现 `bad decrypt` 或导入失败。
  - 生成与使用（Linux/WSL）：
    - `SN=设备背面序列号`
    - `mypassword=$(openssl passwd -1 -salt aV6dW8bD "$SN")`
    - `mypassword=$(eval "echo $mypassword")`
    - 用派生密码加密配置：`openssl aes-256-cbc -pbkdf2 -k "$mypassword" -in RAX3000M_XR30_cfg-telnet-20240117.conf -out cfg_import_config_file_new.conf`
  - 适用批次与证据：20240115、20240117、20240215 等批次大量反馈需 SN 派生（恩山贴 8427780、8395180、8382097；`rmoyulong/cmcc-rax3000me`、`LzxkJ04/RAX3000Me` 提供 Windows 脚本化方案）。

- 同批次差异与快速判定：
  - 个别 20240117 设备仍可用固定密钥，但更常见为 SN 派生；如遇 `bad decrypt` 或导入失败，优先改用 SN 路线。
  - 打开原厂系统日志到 DEBUG，搜索 `openssl aes-256-cbc -pbkdf2 -k`：
    - 若日志出现未加引号的 `$CmDc#RaX30O0M@!$`，实际应使用引号版 `'#RaX30O0M@!$'`；若仍失败，改用 SN 派生。

- 常见错误与处置：
  - `bad decrypt`：常因密钥不匹配或未正确加引号（`!` 在 shell 中需引号保护）；请按上文两条路线分别尝试，务必使用引号。
  - 导入失败：可能为加密方式或批次规则变更导致；若固定密钥与 SN 派生均失败，建议走串口/TTL 或 `mtk_uartboot` 注入恢复→进入 U‑Boot WebUI/TFTP，再完成后续刷写。

- 引用与佐证（精选）：
  - 恩山无线论坛：
    - 8316001（20231027 教程与旧密钥命令）：https://www.right.com.cn/forum/thread-8316001-1-1.html
    - 8320480（免拆教程与旧密钥演示）：https://www.right.com.cn/forum/thread-8320480-1-1.html
    - 8427780（20240115 版 SN 派生密钥教程）：https://www.right.com.cn/forum/thread-8427780-1-1.html
    - 8395180（`bad decrypt` 报错与新版本加固）：https://www.right.com.cn/forum/thread-8395180-1-1.html
    - 8382097（20240117 批次异常与 UARTBoot 救援思路）：https://www.right.com.cn/forum/thread-8382097-1-1.html
  - GitHub/博客：
    - `fanmaomao/CMCC_RAX3000M`（固定密钥与完整流程）：https://github.com/fanmaomao/CMCC_RAX3000M
    - `rmoyulong/cmcc-rax3000me`（SN 派生与固定密钥双路径示例）：https://github.com/rmoyulong/cmcc-rax3000me
    - `LzxkJ04/RAX3000Me`（Windows 脚本化 SN 派生）：https://github.com/LzxkJ04/RAX3000Me
    - `sh1marin`（日志揭示与正确引用方式）：https://blog.sh1mar.in/post/cmcc-rax3000m/

### 入场方式（原厂未必有 WebUI，串口/TFTP 为主）
- 串口入场（强烈推荐）：连接 3.3V TTL（GND/TX/RX，115200），上电按任意键中断启动。多数原厂固件并不启用 U‑Boot 的 HTTP/WebUI，串口是最稳妥的入口；必要时配合电脑 TFTP 服务进行镜像加载与写入。
- WebUI 入场（仅限设备已带 WebUI）：断电→按住 Reset→上电 3–5 秒→松手；若所用 U‑Boot 变种支持 HTTP，则浏览器访问 `http://192.168.1.1/` 可进入 WebUI。若 DHCP 不工作，电脑设静态 `192.168.1.2/255.255.255.0`，网关 `192.168.1.1`。
- 系统内入场（可选，限 NAND）：若 OEM 系统可登录 SSH，NAND 设备可用 `mtd write` 写入 BL2/FIP（见下文“系统内写入”）以替换为带 WebUI 的 U‑Boot；eMMC 的 BL2/FIP不建议在系统内用 `dd` 写入，风险较高。
- 是否具备 WebUI 的判断：
  - 串口日志出现 `U-Boot` 标识且提示 `httpd`/`HTTP server` 启动，或串口菜单含 HTTP/FailSafe 选项，通常表示带 WebUI。
  - 浏览器能否打开 `http://192.168.1.1/` 取决于 U‑Boot 是否启用 HTTP；OEM 的系统管理页面并非 U‑Boot WebUI，不可混淆。

### 备份与回退准备（强烈建议）
- 记录并备份分区：在系统内执行 `cat /proc/mtd`（NAND）并备份关键分区：
  - `nanddump -o -f /tmp/backup-factory.bin /dev/mtdX`（将 `X` 替换为 `factory` 的编号）
  - 如存在 `u-boot-env`：`nanddump -o -f /tmp/backup-uboot-env.bin /dev/mtdY`
  - 通过 `scp /tmp/*.bin` 保存到电脑。
- eMMC 设备：首次进入系统后，务必创建并格式化约 56GB 的数据分区（见下文 eMMC 备注）；BL2/FIP 建议通过 WebUI 刷写，不在系统内用 `dd` 处理。

补充（eMMC 原厂系统的分区级备份示例）：
- 备份 BL2（boot0）：`dd if=/dev/mmcblk0boot0 bs=512 count=2048 of=/tmp/boot0_bl2.bin conv=fsync`
- 备份 GPT：`dd if=/dev/mmcblk0 bs=512 count=34 of=/tmp/mmcblk0_GPT.bin conv=fsync`
- 备份未分区前区：`dd if=/dev/mmcblk0 bs=512 skip=34 count=8158 of=/tmp/mmcblk0_unpartitioned.bin conv=fsync`
- 如存在 `factory`/`fip`/`u-boot-env` 等分区，可按需备份并通过 `scp -O` 下载至电脑。

### 选型建议（什么是“稳定”的 U‑Boot）
- eMMC：
  - ITB（all‑in‑FIT，官方 U‑Boot 布局）：更贴近主线，配套 `.itb` 固件获取简便。可搭配 Developer Drive 的 `emmc-fip-fit.bin`（内置 DHCP + WebUI），或上游 `bl31-uboot.fip`（不含 WebUI，首刷需 TFTP）。
  - BIN（custom layout/单分区）：面向希望使用 `.bin` 固件与 WebUI 的场景。可搭配 Developer Drive 的 `emmc-fip.bin`（内置 DHCP + WebUI），或第三方 WebUI FIP（如 hanwckf 的 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）。
  - 默认建议：
    - 倾向主线与长期维护 → 选 ITB：`emmc-gpt.bin + emmc-bl2.bin + emmc-fip-fit.bin`，后续刷 `.itb`。
    - 明确需要 `.bin` 或自定义分区 → 选 BIN：`emmc-gpt.bin + emmc-bl2.bin + emmc-fip.bin`（或 hanwckf FIP），后续刷 `.bin`。
  - 注：两条路线不可混刷；下载前请按“文件名对照”严格核对介质与文件。
- NAND：
  - 主流与稳定优先选 ITB（OpenWrt U‑Boot layout），使用 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin + immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（OpenWrt 23.05.4 前缀同名），固件用 `.itb`。
  - 若需 BIN 固件（uboot/ubootmod 布局）→ 通常仅需替换 FIP 为支持 BIN 的版本（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`），仅在出现不兼容信号时才更换 BL2。

### 快速导航：按设备查看详细教程

**eMMC（算力版）用户**：
- 新机首刷：跳转到 [eMMC（算力版，64GB）](#emmc算力版64gb) → "新机入手（从 0 到首刷）"
- 版本切换：查看同章节的"降级：24.10 → 23.05"或"升级：23.05 → 24.10"
- 高级操作：参考"系统内写入三件套（DD，高级）"

**NAND（普通版）用户**：
- 新机首刷：跳转到 [NAND（普通版，128MB）](#nand普通版128mb) → "新机入手（从 0 到首刷）"
- 版本切换：查看同章节的"降级：24.10 → 23.05"或"升级：23.05 → 24.10"
- 高级操作：参考"系统内写入（仅 NAND，作为备用）"

TFTP 服务器配置（Windows，新手向）：
- 安装 `Tftpd64`（或 `Tftpd32`），打开后在“Server interfaces”选择你的网卡 `192.168.1.254`，在“Current Directory”设置到包含 `initramfs-recovery.itb` 的文件夹。
- 确认文件名与大小：固件文件需命名为 `initramfs-recovery.itb`（ITB 路线），避免大小写或后缀错误。
- 网卡静态配置：在“网络和共享中心 → 更改适配器设置”，右键你的以太网→属性→`Internet 协议版本 4 (TCP/IPv4)`，设置 IP `192.168.1.254`、子网掩码 `255.255.255.0`、默认网关 `192.168.1.1`。
- 触发恢复：断电→按住 Reset→上电 5–10 秒→指示灯变绿松手，观察 Tftpd64 的“Log Viewer”是否出现设备拉取 `initramfs-recovery.itb` 的记录。

系统内写入（仅 NAND，作为备用）：
- 确认分区：`cat /proc/mtd`，找到 BL2 与 FIP 的实际分区名。
- 写 BL2（仅在不兼容信号出现时）：`mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2`
- 写 FIP（BIN 路线）：`mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
- 若 MTD 只读：安装 `kmod-mtd-rw` 后解锁再写。

免拆（系统内）写入 FIP（常规做法）：
- 上传 FIP 到 `/tmp/`，执行：
  - 官方 ITB 路线：`mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip FIP`
  - 第三方 BIN 路线：`mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
- 完成后断电→按住 Reset→上电 5–10 秒，指示灯变绿松手，进入 U‑Boot（hanwckf 变体会出现 WebUI）。

BL2 更换的判断（复述要点）：默认只换 FIP 即可；如无法进入 WebUI、刷 `.bin` 后立即失败且串口显示早期初始化异常、或 BL2 版本过旧与所选 FIP 不兼容，再考虑更换 BL2。

### 刷写后验证与下一步
- 成功标志：WebUI 固件页能接受目标格式（`.itb` 或 `.bin`），刷入后正常重启进系统。
- eMMC：确认数据分区已创建并挂载；必要时在系统内完成一次性创建与格式化。
- NAND：`dmesg | grep -i ubi` 观察 UBI 初始化是否正常（容量与布局匹配）。
- 出现异常：回到 WebUI 重新对齐三件套（或 FIP），必要时走 TFTP/串口救援。

—
## 流程蓝图（OEM → U‑Boot → 固件）
- eMMC → ITB：`获取 SSH/串口 → 刷 emmc-gpt.bin → 刷 emmc-preloader.bin → 刷 emmc-bl31-uboot.fip 或 emmc-fip-fit.bin → WebUI/TFTP 刷 initramfs-recovery.itb → 系统内升级到 squashfs-sysupgrade.itb`。
 - eMMC → BIN：`获取 SSH/串口 → 刷 emmc-gpt.bin → 刷 emmc-bl2.bin → 刷 emmc-fip.bin 或 hanwckf FIP → WebUI 上传与布局匹配的 BIN 固件 → 首次创建/格式化 56GB 数据分区`。
 - NAND → ITB：`获取 SSH/串口 → 刷 nand-preloader.bin（必要时） → 刷 nand-fip-fit.bin 或官方 immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip → WebUI/TFTP 刷 initramfs-recovery.itb → 系统内升级到 squashfs-sysupgrade.itb`。
 - NAND → BIN：`获取 SSH/串口 → 仅替换 FIP 为 mt7981_cmcc_rax3000m-fip-fixed-parts.bin → WebUI 上传与当前布局匹配的 NAND uboot/ubootmod BIN 固件`。

## 快速总览：硬件版本 × 固件类型 × 所需文件与下载位置

目的：一眼看清“你的介质（eMMC/NAND）当前路线（ITB/BIN）”需要的文件与下载入口，避免混刷。

- eMMC → ITB（all‑in‑FIT，刷 `.itb`）
  - 需要文件：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`、`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
  - 下载位置：
    - U‑Boot 三件套（GPT/BL2/FIP）：`https://drive.wrt.moe/uboot/mediatek/`
    - ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
    - OpenWrt 稳定版（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

- eMMC → BIN（custom U‑Boot layout，单分区，刷 `.bin`）
  - 需要文件（第三方 WebUI FIP）：`mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（hanwckf/bl‑mt798x），以及与你所选布局匹配的 BIN 格式固件。
  - 下载位置：
    - U‑Boot 三件套（BIN 路线）：`https://drive.wrt.moe/uboot/mediatek/`
    - 社区 BIN 固件构建（参考）：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`

- NAND → ITB（主线路线，刷 `.itb`）
  - 需要文件：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（BL2）、`mt7981-cmcc_rax3000m-nand-fip-fit.bin`（FIP/U‑Boot，含 WebUI，优先推荐；或官方 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip` 走 TFTP）、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
  - 下载位置：
    - U‑Boot 三件套（NAND FIT）：`https://drive.wrt.moe/uboot/mediatek/`
    - ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
    - OpenWrt 稳定版（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

- NAND → BIN（uboot/ubootmod，刷 `.bin`）
  - 需要文件：支持 BIN 的 FIP（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）与目标 BIN 格式固件（与所选 uboot/ubootmod 布局一致）。
  - 下载位置：
    - FIP（支持 BIN）：`https://github.com/hanwckf/bl-mt798x/releases`
    - BIN 固件：自建或社区构建（需与所选 uboot/ubootmod 布局匹配）

注意：严禁混刷。“`emmc-*` 仅用于 eMMC”，“`nand-*` 仅用于 NAND”。官方 OpenWrt/ImmortalWrt 的 U‑Boot/FIP 为 `.fip`；hanwckf 的 FIP 以 `.bin` 命名（同为 FIP 容器）。

## eMMC（算力版，64GB）

### 新机入手（从 0 到首刷）
- 识别介质：机身标签显示“CH EC …”多为 eMMC，但也存在少量 CH EC 为 NAND 的个例；请以系统检测为准：存在 `/dev/mmcblk0`/`mmcblk0boot0` 即为 eMMC。亦可用 `df -h` 查看是否有约 56GB 数据盘。
- 进入 U‑Boot WebUI：复位进入 U‑Boot，使用 DHCP 或设静态 `192.168.1.2`，浏览器访问 `http://192.168.1.1/`。
- 首刷路线选择：
  - ITB：建议用 Developer Drive（ImmortalWrt 镜像下载站）的 `emmc-fip-fit.bin`（含 WebUI）→ 在 WebUI 上传 `initramfs-recovery.itb` → 进入系统后升级到 `squashfs-sysupgrade.itb`。
  - BIN：使用 `emmc-gpt.bin + emmc-bl2.bin + emmc-fip.bin`（或社区 WebUI FIP）→ 依次进入 `gpt.html / bl2.html / uboot.html` 刷三件套，再在固件页上传 `.bin`。

### 下载与文件清单（速查）
- ITB：`emmc-gpt.bin`、`emmc-preloader.bin`、`emmc-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`。
 - BIN：`emmc-gpt.bin`、`emmc-bl2.bin`、`emmc-fip.bin`（或 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`，含 WebUI），以及与你所选布局匹配的 BIN 格式固件。

### OEM → OpenWrt（获取 SSH/串口，首刷到系统）
- 工具与准备：
  - 免拆：获取 OEM 的 SSH/Telnet（参考“参考与来源”的 OEM 教程），或通过漏洞/页面启用；已进系统可用 `scp` 上传文件。
  - 串口：USB‑TTL（3.3V，115200 8N1），短接复位进入 U‑Boot；备用 TFTP 服务（PC 设 `192.168.1.254`）。
  - 文件：`emmc-gpt.bin`、`emmc-bl2.bin`（或 `emmc-preloader.bin`）、`emmc-fip-fit.bin` 或 `emmc-fip.bin`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`（或 `.bin`）。
- 系统内（免拆，推荐）：
  1) `scp` 把三件套上传到路由器 `/tmp/`，校验 `md5sum`。
  2) 执行 dd：
     - `dd if=mt7981-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync`
     - `echo 0 > /sys/block/mmcblk0boot0/force_ro`
     - `dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync`
     - `dd if=mt7981-cmcc_rax3000m-emmc-bl2.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync`
     - `dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync`
     - ITB：`dd if=mt7981-cmcc_rax3000m-emmc-fip-fit.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync`；BIN：`dd if=mt7981_cmcc_rax3000m-fip-fixed-parts.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync`
  3) 断电重启：
     - Developer Drive/hanwckf FIP（含 WebUI）：在 WebUI 上传 `initramfs-recovery.itb`（ITB）或 `.bin`（BIN）。
     - 上游官方 FIP（无 WebUI）：走 TFTP 上传 `initramfs-recovery.itb`，进入系统后升级到 `squashfs-sysupgrade.itb`。
- 串口/TFTP（备选）：在 U‑Boot 中配置网络，`tftpboot` 加载 `initramfs-recovery.itb`，再在系统内升级到 `squashfs-sysupgrade.itb`。
  - 注意：eMMC 的 GPT/BL2/FIP 顺序不可乱；刷后进入对应 WebUI，再进行固件首刷。

### 降级：24.10 → 23.05（切换到 BIN/单分区）
- 目标：U‑Boot 接受 `.bin`，配合 WebUI 刷 BIN 固件。
- 步骤：
  1) 切到单分区三件套：`gpt.html → bl2.html → uboot.html`（或系统内 dd）。
  2) 选择带 WebUI 的 FIP（推荐 Developer Drive/hanwckf）。
 3) WebUI 固件页上传与单分区布局匹配的 BIN 格式固件。
- 注意事项：
  - 严禁混刷；`emmc-*` 与 `nand-*` 不可交叉使用。
  - 首次进入单分区后按需创建并格式化 ~56GB 数据分区（`cfdisk + mkfs.ext4`）。
  - 23.05/24.10 的 ITB 文件名保持一致（`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`）；BIN 包需与所选布局一致（单分区/ubootmod）。

### 升级：23.05 → 24.10（切换到 ITB/all‑in‑FIT）
- 目标：U‑Boot 接受 `.itb`，走官方布局。
- 步骤：
  1) 切到 ITB 三件套：`emmc-gpt.bin → emmc-preloader.bin → emmc-bl31-uboot.fip`（页面或 dd）。
  2) 使用 Developer Drive 的 `emmc-fip-fit.bin`（含 WebUI）或上游 `bl31-uboot.fip`（无 WebUI）。
  3) 首刷 `initramfs-recovery.itb`，进入系统后升级到 `squashfs-sysupgrade.itb`。
- 注意事项：
  - 优先 WebUI（FIP 含 WebUI）；无 WebUI 时走 TFTP 作为替代。
  - 刷前校验哈希，备份关键分区，顺序严格遵守。
  - 若改用官方 `bl31-uboot.fip`（无 WebUI），请准备 TFTP；Developer Drive 的 `emmc-fip-fit.bin`/`nand-fip-fit.bin` 更适合纯浏览器流程。

### 升级到 ITB 路线（eMMC all‑in‑FIT）

准备文件（建议从官方镜像库与选择器获取）：
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`（GPT）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`（BL2/Preloader）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip`（FIP/U‑Boot，官方 `.fip` 扩展名）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb`（先刷此）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-squashfs-sysupgrade.itb`（系统内再升级到此）

下载页面与示例：
- GPT/BL2/FIP（eMMC all‑in‑FIT）：`https://drive.wrt.moe/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`emmc` 的 `gpt.bin`、`preloader.bin`、`bl31-uboot.fip`）
- ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`（下载 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`）

文件完整性校验（强烈建议）：
- 在下载页面获取 `sha256sums` 或固件详细页的 `SHA256`，并在主机上校验：`sha256sum <文件名>` 比对哈希。
- 也可使用 `md5sum <文件名>` 作为辅助；但以 SHA256 为准。
- 校验通过后再进行刷写，可显著降低因下载损坏导致的启动失败风险。

首次固件写入（优先 WebUI，备用 TFTP）：
- Developer Drive/hanwckf FIP（含 DHCP + WebUI）→ WebUI：浏览器访问 `http://192.168.1.1/` 或 `http://192.168.1.1/uboot.html`，上传 `initramfs-recovery.itb`，进入临时系统后在系统内升级到 `squashfs-sysupgrade.itb`。
- 上游官方 FIP（通常不含 WebUI）→ TFTP：将 PC 设为 `192.168.1.254`，启动 TFTP，断电→按住 Reset→上电，等待 U‑Boot 拉取 `initramfs-recovery.itb`，进入临时系统后再升级到 `squashfs-sysupgrade.itb`。

备注：该路线对应 eMMC 的 all‑in‑FIT 分区；若固件未集成自动扩容脚本，则首次进入系统后可用 `cfdisk /dev/mmcblk0` 新建并 `mkfs.ext4` 格式化数据分区（一次性操作）。

eMMC 手动扩容示例（仅首次执行一次）：
- 确认设备与空闲空间：`lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT /dev/mmcblk0`
- 启动分区工具：`cfdisk /dev/mmcblk0`（选择空闲空间，新建 `primary` 分区，写入保存并退出）
- 格式化新分区：`mkfs.ext4 -L data /dev/mmcblk0p3`（若 p3 已被占用，请按实际分区号调整）
- 挂载验证：`mkdir -p /mnt/data && mount /dev/mmcblk0p3 /mnt/data && df -h /mnt/data`
- 可选持久化挂载：`blkid /dev/mmcblk0p3` 获取 `UUID`，在 `/etc/fstab` 添加如 `UUID=<uuid> /mnt/data ext4 defaults 0 2`（注意 OpenWrt 的 `fstab` 位置与格式可能不同，可通过 LuCI 系统挂载点配置）

### 降级到 BIN 路线（custom U‑Boot layout，单分区）
目的：让 U‑Boot 接受 `.bin` 并用 WebUI 刷 BIN 固件。

准备文件（官方镜像库）：
- `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（FIP/U‑Boot，含 WebUI；来自 hanwckf/bl‑mt798x）
 - BIN 固件：与单分区布局匹配的 BIN 格式固件（官方或自建）

下载页面与示例：
- FIP（含 WebUI）：`https://github.com/hanwckf/bl-mt798x/releases`
- BIN 固件（eMMC 单分区）：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`

WebUI 操作顺序：
1. `gpt.html` → 上传并刷入单分区 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin` → 重启回 U‑Boot。
2. `bl2.html` → 上传并刷入单分区 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-bl2.bin` → 重启回 U‑Boot。
3. `uboot.html` → 上传并刷入单分区 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-fip.bin` → 重启回 U‑Boot。
4. 固件上传页面 → 刷入与所选布局匹配的 BIN 格式固件。

备注：首次进入“单分区”后，可按需创建并格式化 eMMC 的数据分区（约 56GB），或使用固件内的扩容机制（若已集成）。

### 系统内写入三件套（DD，高级）
- 上传三件套到 `/tmp/` 并校验 `md5sum`；按以下顺序执行：
  - `dd if=mt7981-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync`
  - `echo 0 > /sys/block/mmcblk0boot0/force_ro`
  - `dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync`
  - `dd if=mt7981-cmcc_rax3000m-emmc-bl2.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync`
  - `dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync`
  - ITB 路线：`dd if=mt7981-cmcc_rax3000m-emmc-fip-fit.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync`
  - BIN 路线（WebUI FIP）：`dd if=mt7981_cmcc_rax3000m-fip-fixed-parts.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync`
- 断电重启后，按你的 FIP 变体选择 WebUI 或 TFTP 路径进行首次固件写入。
  - 系统内 `dd` 仅建议在 eMMC 上由熟练用户执行；NAND 首选通过 WebUI/mtd 完成写入以降低风险。

### 注意事项与常见问题（eMMC）
- 路线必须匹配：`custom layout/单分区` → BIN；`all‑in‑FIT` → ITB，文件不可交叉使用。
- 刷写顺序严谨：GPT → BL2 → FIP → 固件（ITB 或 BIN）。其间断电重启，确保进入对应的 U‑Boot 变体。
- 校验镜像哈希（SHA256/MD5），避免下载损坏导致不可启动。
- eMMC 单分区首次进入系统后需创建并格式化大数据分区（约 56GB），建议一次性用 `cfdisk + mkfs.ext4` 完成。
- 若 WebUI 上传失败或浏览器异常，优先更换浏览器；必要时改走 TFTP（仅在上游官方 FIP 无 WebUI 时）。
 - 若设备来自新批次 OEM（如 1214），系统内获取 SSH 需按加密配置文件的解密方式处理；详见“从原厂系统开启 SSH 权限”。

—

## NAND（普通版，128MB）

### 新机入手（从 0 到首刷）
- 识别介质：机身标签显示“CH …”（不含 EC）多为 NAND，但也可能出现 “CH EC”为 NAND 的情况；请以系统检测为准：`cat /proc/mtd` 出现 UBI 分区且不存在 `/dev/mmcblk0*` 即为 NAND。
- 进入 U‑Boot WebUI：复位进入 U‑Boot，若当前 FIP 含 WebUI（如 hanwckf 变体或部分社区 FIP），浏览器访问 `http://192.168.1.1/`。
- 首刷路线选择：
  - ITB：`bl2.html → uboot.html` 刷 BL2/FIP 后，在 WebUI 上传 `initramfs-recovery.itb`，进入系统后升级到 `squashfs-sysupgrade.itb`。若当前使用上游官方 `bl31-uboot.fip`（无 WebUI），请走 TFTP 或先替换为带 WebUI 的 `mt7981-cmcc_rax3000m-nand-fip-fit.bin`。
  - BIN：在 WebUI 上传 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（启用 BIN 支持），随后上传与当前布局匹配的 BIN 固件（示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`）。

### 下载与文件清单（速查）
- ITB：`nand-preloader.bin`、`nand-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`。
 - BIN：`mt7981_cmcc_rax3000m-fip-fixed-parts.bin`、与所选布局匹配的 BIN 固件（示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`）。

### OEM → OpenWrt（获取 SSH/串口，首刷到系统）
- 工具与准备：
  - 免拆：获取 OEM 的 SSH/Telnet；在系统内用 `scp` 上传 `nand-preloader.bin`/`nand-bl31-uboot.fip`/固件。
  - 串口：USB‑TTL（3.3V，115200 8N1），进入 U‑Boot；备用 TFTP 服务（PC 设 `192.168.1.254`）。
  - 文件：`nand-preloader.bin`、`nand-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`（或 `.bin`）。
- 系统内（免拆，推荐）：
  1) `scp` 上传到 `/tmp/`，校验 `md5sum`。
  2) 写入：`mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2`；`mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip FIP`。
  3) 重启回 U‑Boot：
     - FIP 含 WebUI（hanwckf/社区）：在 WebUI 上传 `initramfs-recovery.itb` 或 `.bin`。
     - 上游官方 FIP（无 WebUI）：走 TFTP 上传 `initramfs-recovery.itb`。
- 串口/TFTP（备选）：在 U‑Boot 中 `tftpboot` 加载 `initramfs-recovery.itb`，进入系统后再升级到 `squashfs-sysupgrade.itb`。
  - 注意：NAND 无 GPT；优先只替换 FIP，BL2 更换仅在必要时。

### 降级：24.10 → 23.05（切换到 BIN/uboot/ubootmod）
- 目标：U‑Boot 接受 `.bin`，配合 WebUI 刷 BIN 固件。
- 步骤：
  1) WebUI 上传 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（启用 BIN 支持）。
  2) 上传与当前布局匹配的 BIN 固件（示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`）。
- 注意事项：
  - 布局必须匹配（UBI 容量差异）。
  - 若 WebUI 不可用，先替换为带 WebUI 的 FIP 或走 TFTP。

### 升级：23.05 → 24.10（切换到 ITB/OpenWrt U‑Boot layout）
- 目标：U‑Boot 接受 `.itb`，走官方布局。
- 步骤：
  1) 切到 ITB 三件套：`nand-preloader.bin → nand-bl31-uboot.fip`（页面或系统内 mtd）。
  2) 在 WebUI 上传 `initramfs-recovery.itb`，进入系统后升级到 `squashfs-sysupgrade.itb`；若 FIP 无 WebUI，则走 TFTP。
- 注意事项：
  - 刷前校验哈希；备份关键分区；顺序严格遵守。

### 重要说明（避免混淆）
 - 官方 OpenWrt/ImmortalWrt 的 NAND FIP 文件名示例为 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（通常不含 WebUI，首刷走 TFTP）。
- 需要 WebUI 或 BIN 固件时，请改用 hanwckf 的 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（含 WebUI，支持 `.bin`）。

### 升级到 ITB 路线（OpenWrt U‑Boot layout）
目的：让 U‑Boot 接受 `.itb` 并用 WebUI 刷 ITB 固件。

准备文件（官方镜像库与选择器）：
- `openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（BL2/Preloader）
 - 推荐：`mt7981-cmcc_rax3000m-nand-fip-fit.bin`（FIP/U‑Boot，含 WebUI）；备选：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip`（官方 `.fip`，通常无 WebUI，需 TFTP）
 - ITB 固件：`initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`

下载页面与示例：
- BL2/FIP（NAND ITB 路线）：`https://drive.wrt.moe/uboot/mediatek/`（主线 drive 提供：`mt7981-cmcc_rax3000m-nand-preloader.bin`、`mt7981-cmcc_rax3000m-nand-fip-fit.bin`、`mt7981-cmcc_rax3000m-nand-fip-stock.bin`、`mt7981-cmcc_rax3000m-nand-fip-expand.bin` 等；官方 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip` 可在发行版目录中获取）
- ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m` 或 `https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

FIP 变体说明（NAND）：
- `nand-fip-fit.bin`：含 WebUI（推荐），支持 Web 页刷 ITB/BIN。
- `nand-fip-stock.bin`：接近厂商原始布局，UBI 容量较保守。
- `nand-fip-expand.bin`：在不改变核心分区前提下扩大 UBI/overlay，可用于提升可用空间；刷入前确认与你当前固件布局兼容。

WebUI 操作顺序：
1. `bl2.html` → 上传并刷入 NAND Preloader → 重启回 U‑Boot。
2. `uboot.html` → 上传并刷入 NAND FIP（推荐 `nand-fip-fit.bin`，含 WebUI）→ 重启回 U‑Boot。
3. 固件上传页面 → 先刷 `initramfs-recovery.itb`，进入系统，再升级到 `squashfs-sysupgrade.itb`。

布局说明：NAND 有 `stock/uboot/ubootmod` 多种分区布局（UBI 容量不同），所刷 ITB 固件需与当前布局匹配。

### 降级到 BIN 路线（uboot / ubootmod）
目的：让 U‑Boot 接受 `.bin` 并用 WebUI 刷 BIN 固件。

准备文件：
- `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（FIP/U‑Boot，常用于恢复/启用 BIN 支持）→ `https://github.com/hanwckf/bl-mt798x/releases`
 - BIN 固件：示例 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`（与你选择的 `uboot/ubootmod` 布局一致）
 - 可选（仅在需要时更换 BL2）：`openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（兼容的 BL2/Preloader）

下载页面与示例：
 - FIP 固件（恢复 BIN 支持）：`https://github.com/hanwckf/bl-mt798x/releases`（在对应 release 资产中获取 `mt798x-uboot-fip.7z`，解压得到 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）
- BIN 固件（NAND 布局匹配）：`https://downloads.immortalwrt.org/` 或第三方构建，注意选择 `nand-uboot`/`nand-ubootmod` 的 `squashfs-sysupgrade.bin`
 - BL2/Preloader（若需要更换）：请到 ImmortalWrt 发布目录查找（示例为 24.10 稳定版）：`https://downloads.immortalwrt.org/releases/24.10.0/targets/mediatek/filogic/`，文件名示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`。若该版本目录暂未提供，可改用 OpenWrt 发布目录：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/` 搜索 `cmcc_rax3000m-nand-preloader.bin`。
   注：`uboot/mediatek` 镜像库主要提供 FIP（以及 eMMC 的 GPT/BL2）；NAND 的 Preloader 通常随发行版发布在 `releases/24.10.0/targets/mediatek/filogic/` 等目录（以具体版本为准）。

是否需要刷 BL2？（给出明确判断）
- 默认结论：切到 BIN 路线通常“仅替换 FIP”即可，不需要更换 BL2。
- 触发更换 BL2 的典型信号：
  - 写入 BIN‑FIP 后无法进入 U‑Boot WebUI（串口停在早期初始化或反复重启）。
  - WebUI 能出现但刷入 `.bin` 后立即失败，且串口提示 DDR/早期初始化异常。
  - 设备仍使用较老或 OEM 的 BL2，与所选 FIP 路线存在不兼容历史。
- 如何确认分区名：`cat /proc/mtd`，记录 `BL2` 或 `Preloader`、`FIP` 的实际分区名（以下命令中的分区名需按你的设备替换）。

更换 BL2 的步骤（仅在上述信号出现时执行）：
 1. 将 `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin` 上传到路由器的 `/tmp/`。
2. 执行写入（示例，分区名以实际为准）：
   - `mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2`
3. 重启回 U‑Boot，确认能进入 WebUI；如仍异常，再次写入 BIN‑FIP 并重启：
   - `mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
4. WebUI 页面应能选择并接受 `.bin` 固件。
注意：若 MTD 设备只读，可安装 `kmod-mtd-rw` 后解锁再写入；刷错 BL2 风险更高，务必串口在线或准备 TFTP 恢复方案。

### 注意事项与常见问题（NAND）
- 路线与布局匹配：`stock/uboot/ubootmod` 的 UBI 容量不同，所刷 `.bin` 必须与当前布局一致。
- FIP 的 WebUI 差异：上游官方 `bl31-uboot.fip` 通常不含 WebUI；hanwckf 变体与部分社区 FIP 内置 WebUI，可直接用浏览器操作。
- BL2 更换仅在必要时：优先只替换 FIP；若出现早期初始化或反复重启等信号，再考虑更换 BL2。
- 刷前校验哈希并备份关键分区（`factory`/`u-boot-env`），以便快速回退。
- 若 WebUI 页面不可用或上传失败，先更换浏览器；必要时改走 TFTP 或暂时刷入带 WebUI 的 FIP。

WebUI 操作顺序：
1. `uboot.html` → 上传并刷入 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin` → 重启回 U‑Boot。
2. 固件上传页面 → 刷入 `.bin`（布局需匹配：`stock/uboot/ubootmod`）。

—

## 成功判定与回退
- 切换完成后，固件上传页面会接受对应格式（`.itb` 或 `.bin`）；刷入后设备应自动重启并进入系统。
- 若刷入后无法启动：
  - eMMC：在 WebUI 重新对齐 GPT/BL2/FIP（切回另一套），或用 TFTP 恢复。
  - NAND：重新刷 FIP（BIN/ITB 对应的），必要时用 TFTP 恢复。

—

## 校验与风险提示
- 严禁混刷：`emmc-*` 仅用于 eMMC；`nand-*` 仅用于 NAND。
- 路线必须匹配：单分区（custom layout）→ BIN；all‑in‑FIT（OpenWrt U‑Boot layout）→ ITB。
- 刷写顺序严格遵守：GPT → BL2 → FIP → 固件（ITB 或 BIN）。
- 刷前校验文件哈希，备份 `factory`/`u-boot-env` 等关键分区以便回退。
- eMMC 单分区首次需要在系统内创建并格式化大数据分区（约 56GB）。
- NAND 的 52MHz 闪存频率固件在部分设备可能出现 I/O 报错，建议优先使用 26MHz 或确认设备体质。
 - 回厂（NAND）：不要直接回刷整机备份（易触发 ECC 校验错误）。建议流程为：备份 `Factory` → 刷过渡全盘镜像（含不死 U‑Boot）→ WebUI 刷原厂 `factory` 包 → 写回 `Factory` 备份并重启。

—

## 版本兼容性说明（快速核对）
- 固件格式与路线：`ITB ↔ all‑in‑FIT`，`BIN ↔ custom/uboot/ubootmod`；两者不可混刷。
 - FIP 类型：官方 `emmc-bl31-uboot.fip` 或 `nand-bl31-uboot.fip` 通常不含 WebUI；Developer Drive 的 `emmc-fip-fit.bin`、`nand-fip-fit.bin` 与 hanwckf 的 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin` 内置 WebUI。
- 介质限制：`emmc-*` 文件仅用于 eMMC；`nand-*` 文件仅用于 NAND。
 - 版本前缀：ImmortalWrt 使用 `immortalwrt-<版本>-`，OpenWrt 使用 `openwrt-<版本>-`；设备与介质后缀一致；下载时按镜像站选择正确前缀。
- ITB 文件名：各版本保持 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb` 的命名一致。

—

## 快速文件清单示例（命名以官方/社区实际发布为准）
- eMMC → ITB 路线：
- `emmc-gpt.bin`、`emmc-preloader.bin`、`emmc-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
- eMMC → BIN 路线：
  - `emmc-gpt.bin`、`emmc-bl2.bin`、`emmc-fip.bin`、与布局匹配的 BIN 格式固件
- NAND → ITB 路线：
- `nand-preloader.bin`、`nand-bl31-uboot.fip`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
- NAND → BIN 路线：
  - `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`、与所选布局匹配的 BIN 固件（示例：`immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`）

—

## 参考与来源
- U‑Boot 镜像库（含 cmcc_rax3000m eMMC/NAND 三件套）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`
- eMMC 单分区路线与操作说明：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc`
- eMMC 单分区社区构建（闭源驱动路线）：`https://github.com/kkstone/Actions-RAX3000M-EMMC`
- NAND 布局与 FIP（BIN 支持）参考：`https://github.com/hanwckf/bl-mt798x/releases`、`https://github.com/ytalm/openwrt-rax3000m-nand`
- OpenWrt 对 RAX3000M 的支持说明（含 eMMC/NAND 指南与 all‑in‑FIT 路线）：`https://github.com/openwrt/openwrt/pull/13513`
 - OEM 获取 SSH 权限与免拆流程（示例教程）：知乎 `CMCC RAX3000M算力版EMMC刷机OpenWrt教程＆玩机报告`（https://zhuanlan.zhihu.com/p/696434968）
 - NAND 获取 SSH 与 FIP 写入示例（社区博客）：`https://hjfrun.com/note/rax3000m-nand`
 - OEM 解密配置与备份/刷机示例（GitHub 整理贴）：`https://github.com/fanmaomao/CMCC_RAX3000M`
 - eMMC dd 三件套与路线选择讨论（知乎教程）：`https://zhuanlan.zhihu.com/p/688078113`
