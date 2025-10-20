# RAX3000M U-Boot WebUI 升级/降级指南

面向 CMCC RAX3000M 的 eMMC（算力版）与 NAND（普通版），本指南提供“仅通过 U-Boot WebUI”完成从支持 BIN 的 U-Boot 切换到支持 ITB（FIT）的 U-Boot，或反向降级回支持 BIN 的 U-Boot，并最终通过 WebUI 刷入系统固件（`.bin` 或 `.itb`）。

指南要点：
- U-Boot WebUI 变种通常提供专用页面：`gpt.html`（GPT）、`bl2.html`（Preloader/BL2）、`uboot.html`（FIP/U‑Boot 本体），以及固件上传页面（接受 `.bin` 或 `.itb`）。
- 原厂 U‑Boot 未必自带 WebUI；是否可用需以实机检测为准（见“新机原厂固件→稳定 U‑Boot”章节）。
- 选择“ITB 路线”或“BIN 路线”时，必须对应刷入匹配的 GPT/BL2/FIP 套件；完成后，固件页面才会接受你想要的格式。
- 在“具备 WebUI”这一前提下可全程通过浏览器完成；若设备出厂不带 WebUI，请先按“新机原厂固件→稳定 U‑Boot”章节通过串口/TFTP或系统内（仅 NAND）替换为带 WebUI 的 U‑Boot，再继续本文的 WebUI 流程。

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

## 下载来源（官方/社区）
- U‑Boot 三件套（GPT/BL2/FIP）官方镜像库：`https://drive.wrt.moe/uboot/mediatek/`
  - 选择与设备介质匹配的 `cmcc_rax3000m` 的 `emmc` 或 `nand` 版本；注意区分“all‑in‑FIT（ITB 路线）”与“custom U‑Boot layout（单分区，BIN 路线）”。
- ImmortalWrt 24.10.0 ITB 固件（官方选择器）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
  - 可下载 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`。
- OpenWrt 主线 ITB 固件（备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`
- eMMC 单分区 BIN 固件（闭源驱动路线）社区构建：
  - `https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`
  - `https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`
- NAND 侧用于恢复 BIN 支持的 FIP（常见变体）：
  - `https://github.com/hanwckf/bl-mt798x/releases`（例如 20231124 版本，包含适配 MT7981 的 FIP 固件）

### 快速入口（页面直链）
- U‑Boot 三件套目录（GPT/BL2/FIP）：`https://drive.wrt.moe/uboot/mediatek/`
- ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
- OpenWrt 固件目录（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`
- eMMC BIN 社区构建：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`
- NAND BIN FIP 发布页：`https://github.com/hanwckf/bl-mt798x/releases`

说明：ImmortalWrt 的下载站可能出现人机验证（Cloudflare），请耐心等待或更换浏览器；文件命名随发布版本略有差异，按下文的“示例文件名与下载页面”匹配设备介质与路线即可。

—

## 新机原厂固件 → 稳定 U‑Boot（选型与完整步骤）

 - 拆机参考视频： https://www.bilibili.com/video/BV1q6MCzWExX/

目的：拿到新机（OEM 出厂系统）时，从零开始选择稳定的 U‑Boot 路线（ITB 或 BIN），并完成从入场、备份到刷写与验证的完整流程。

### 从原厂系统开启 SSH 权限（免拆，NAND/eMMC 通用）
- 适用：原厂系统后台可导入/导出配置，常见默认管理地址 `http://192.168.10.1/`。
- 总体流程：导出配置 → 解密解包 → 修改开启 SSH 与清空 root 密码 → 加密打包 → 导入 → 用 `ssh` 登录。
- 具体步骤：
  1) 在后台“配置管理 → 导出配置”，得到 `cfg_export_config_file.conf`。
  2) 在 Linux/WSL 解密并解包（密钥通常为 `$CmDc#RaX30O0M@\!$`）：
     - `openssl aes-256-cbc -d -pbkdf2 -k $CmDc#RaX30O0M@\!$ -in cfg_export_config_file.conf -out - | tar -zxvf -`
  3) 修改配置：
     - 编辑 `etc/config/dropbear`，将 `option enable '0'` 改为 `option enable '1'`（开启 SSH）。
     - 编辑 `/etc/shadow`，清空 `root` 两个冒号间的密码哈希（置空以免密码）。
  4) 重新压包并加密：
     - `tar -zcvf - etc | openssl aes-256-cbc -pbkdf2 -k $CmDc#RaX30O0M@\!$ -out cfg_export_config_file_new.conf`
  5) 返回后台“配置管理 → 导入配置”，选择 `cfg_export_config_file_new.conf`，设备重启后可用 `ssh` 登录：
     - `ssh root@192.168.10.1`（默认免密登录）。
  6) 传输文件时如遇 `sftp-server: not found`，请用 `scp -O` 参数：
     - `scp -O <本地文件> root@192.168.10.1:/tmp/`
- 参考教程：知乎/博客与社区贴均给出上述流程与密钥示例（不同批次如密钥失败，请查看系统日志或对应教程获取密钥）。

### 另一种解决方案：SN 派生密钥 + Telnet/TFTP 入场（适用于后加密/地区版）

适用场景
- 适用于后加密批次或特殊地区版（如广东版），固定密钥与通用 openssl 解密失败（bad decrypt）。
- 思路：按 SN 派生密码 → 用派生密码加密 Telnet 解锁配置 → 导入开启 Telnet → 通过 Telnet 拉取并写入 FIP/UBoot → 进入 U-Boot 执行既有流程。

前置准备
- Linux/WSL/Ubuntu 终端，已安装 `openssl`、`wget`。
- Windows 下准备 Telnet 客户端（系统自带或 `PuTTY`）、`Tftpd64` 便携版。
- 路由与 PC 直连同网段；记下 PC 网卡 `IP`（示例 `192.168.1.100`）。

步骤
1. 读取设备 SN
- 在设备背面标签找到序列号，示例：`SN=5D11210006XXXXX`
- 在 Linux 终端执行：`SN=5D11210006XXXXX`

2. 生成派生密码
- `mypassword=$(openssl passwd -1 -salt aV6dW8bD "$SN")`
- `mypassword=$(eval "echo $mypassword")`
- `echo $mypassword"`

3. 下载 Telnet 解锁配置模板
- `wget "https://github.com/Daniel-Hwang/RAX3000Me/raw/refs/heads/main/20241111-RAX3000Me_Step12-TelnetUboot/RAX3000M_XR30_cfg-telnet-20240117.conf"`
- 如链接失效，请参考“参考与来源”或社区镜像。

4. 用派生密码加密配置并生成导入包
- `openssl aes-256-cbc -pbkdf2 -k "$mypassword" -in RAX3000M_XR30_cfg-telnet-20240117.conf -out cfg_import_config_file_new.conf`

5. 导入配置以开启 Telnet
- 通过原厂 WebUI 的“配置导入/恢复”入口导入 `cfg_import_config_file_new.conf`。
- 成功后，Telnet 端口 `23` 开启，路由 IP 记为 `R_IP`（常见为 `192.168.1.1` 或 `192.168.10.1`）。

6. 连接 Telnet
- Windows：在 PowerShell/命令提示符执行 `telnet <R_IP>`；或使用 `PuTTY` 选择 `Telnet` 协议。
- Linux/WSL：`telnet <R_IP>`

7. 准备 Tftpd64（Windows）
- 下载并解压 Tftpd64 便携版（官方 Releases：`https://github.com/PJO2/tftpd64/releases` ，选择 64-bit portable ZIP）。
- 打开 `tftpd64.exe`，切换到 `Log Viewer`；`Current Directory` 指向 U-Boot/FIP 文件所在目录；`Server interface` 选择 `PC_IP` 网卡。

8. 在路由 Telnet 中拉取文件到 `/tmp`
- 示例命令：`tftp -g -r <fip_or_uboot.bin> -l /tmp/<fip_or_uboot.bin> <PC_IP>`
- 传输成功将在 Tftpd64 的 Log 中看到 RRQ 记录。

9. 写入 FIP/UBoot

- eMMC 命令示例 `dd if=/tmp/mt7981_cmcc_rax3000m-emmc-fip.bin of=/dev/mmcblk0p3`
- NAND 命令示例 `mtd write /tmp/mt7981-cmcc_rax3000m-nand-fip-fit.bin FIP`

- 预期输出类似 `1148+1 records in` / `1148+1 records out`；随后执行 `sync`

10. 进入 U-Boot 并继续后续刷机
- 断电 → 按住 `Reset` → 上电 5–10 秒 → 指示灯变红/绿后松手。
- 浏览器访问 `http://192.168.1.1/` 进入 U-Boot 页面，按本指南既有 `itb/bin` 流程操作。

注意与提示
- 命令中的密码变量必须使用双引号：`"$mypassword"`，避免 `$`、`!` 等字符被 Shell 解释。
- `R_IP` 与 `PC_IP` 请替换为实际地址；若 Telnet 连接失败，重试导入配置或检查网段/防火墙。
- NAND/eMMC 的分区设备号不同，`dd` 目标需按机型/介质确认；误写将导致不可启动。
- 若仍出现 `bad decrypt` 或配置上传失败，请改回“固定密钥路线”或参考“密钥参考”区块的故障排查。

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
  - 优先推荐 ITB（all‑in‑FIT，官方 U‑Boot 布局）→ 更贴近主线，配套固件获取简单；需要先刷 `initramfs-recovery.itb` 再升到 `sysupgrade.itb`。
  - 若希望使用闭源驱动路线或现有 `.bin` 固件生态 → 选择 BIN（custom U‑Boot layout，单分区），对应 `...-emmc-gpt.bin / -emmc-bl2.bin / -emmc-fip.bin` 三件套与 `.bin` 固件。
- NAND：
  - 主流与稳定优先选 ITB（OpenWrt U‑Boot layout），使用 `...-nand-preloader.bin + ...-nand-fip.fit/bin`，固件用 `.itb`。
  - 若需 BIN 固件（uboot/ubootmod 布局）→ 通常仅需替换 FIP 为支持 BIN 的版本（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`），仅在出现不兼容信号时才更换 BL2。

### eMMC：从 OEM 到 ITB/BIN（WebUI 全流程）
准备文件与下载：
- ITB 路线：`...-emmc-gpt.bin`、`...-emmc-preloader.bin`、`...-emmc-fip.fit/bin`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
  - 三件套：`https://drive.wrt.moe/uboot/mediatek/`
  - ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
- BIN 路线：`mt7981-cmcc_rax3000m-emmc-gpt.bin`、`...-emmc-bl2.bin`、`...-emmc-fip.bin`、目标 `.bin`
  - 三件套：同上镜像库；BIN 固件可参考社区构建链接。

操作顺序（WebUI）：
1. `gpt.html` → 刷 `...-emmc-gpt.bin` → 重启回 U‑Boot。
2. `bl2.html` → 刷 `...-emmc-preloader.bin`（或 BIN 路线的 `...-emmc-bl2.bin`）→ 重启回 U‑Boot。
3. `uboot.html` → 刷 `...-emmc-fip.fit/bin` → 重启回 U‑Boot。
4. 固件页面：
   - ITB 路线 → 先刷 `initramfs-recovery.itb`，进临时系统后再升到 `squashfs-sysupgrade.itb`。
   - BIN 路线 → 直接刷 `.bin`。

eMMC 备注（数据分区）：单分区与 all‑in‑FIT 路线均不会自动创建最后约 56GB 的数据分区。首次进入系统后：
- `cfdisk /dev/mmcblk0` 新建数据分区（保持对齐）。
- `mkfs.ext4 /dev/mmcblk0pX`（将 `X` 替换为新分区号）。此操作只需一次，后续固件会自动挂载。

免拆（系统内）写入三件套（仅在无 WebUI、确认风险可控时）：
- 上传三件套到 `/tmp/` 并校验 `md5sum`；执行：
  - `dd if=mt7981-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync`
  - `echo 0 > /sys/block/mmcblk0boot0/force_ro`
  - `dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync`
  - `dd if=mt7981-cmcc_rax3000m-emmc-bl2.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync`
  - `dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync`
  - `dd if=mt7981-cmcc_rax3000m-emmc-fip.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync`
- 重启后进入 U‑Boot；新版 custom U‑Boot 支持 DHCP，可直接浏览器进入 WebUI 刷固件。

### NAND：从 OEM 到 ITB/BIN（WebUI + 系统内）
准备文件与下载：
- ITB 路线：`...-nand-preloader.bin`（BL2）+ `...-nand-fip.fit/bin`（或 `-expand.bin / -stock.bin` 变体）+ `initramfs-recovery.itb / sysupgrade.itb`
  - 下载：镜像库与固件选择器同上。
- BIN 路线：支持 BIN 的 FIP（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）+ 目标 `.bin` 固件；仅在需要时准备 `...-nand-preloader.bin`。
  - 下载：FIP（`hanwckf/bl-mt798x`），BL2（镜像库）。

操作顺序（WebUI）：
1. ITB 路线：`bl2.html` → 刷 NAND Preloader → 重启；`uboot.html` → 刷 NAND FIP（FIT 支持）→ 重启；固件页面 → `initramfs.itb` → 系统内升到 `sysupgrade.itb`。
2. BIN 路线：`uboot.html` → 刷 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin` → 重启；固件页面 → 刷 `.bin`（与你的 `uboot/ubootmod` 布局一致）。

系统内写入（仅 NAND，作为备用）：
- 确认分区：`cat /proc/mtd`，找到 BL2 与 FIP 的实际分区名。
- 写 BL2（仅在不兼容信号出现时）：`mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2`
- 写 FIP（BIN 路线）：`mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
- 若 MTD 只读：安装 `kmod-mtd-rw` 后解锁再写。

免拆（系统内）写入 FIP（常规做法）：
- 上传 FIP 到 `/tmp/`，执行：`mtd write /tmp/<fip>.bin FIP`
- 示例（FIT 路线）：`mtd write /tmp/mt7981-cmcc_rax3000m-nand-fip-expand.bin FIP`
- 示例（BIN 路线）：`mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
- 完成后断电→按住 Reset→上电 5–10 秒，指示灯变绿松手，进入 U‑Boot（若为支持 HTTP 的变种则出现 WebUI）。

BL2 更换的判断（复述要点）：默认只换 FIP 即可；如无法进入 WebUI、刷 `.bin` 后立即失败且串口显示早期初始化异常、或 BL2 版本过旧与所选 FIP 不兼容，再考虑更换 BL2。

### 刷写后验证与下一步
- 成功标志：WebUI 固件页能接受目标格式（`.itb` 或 `.bin`），刷入后正常重启进系统。
- eMMC：确认数据分区已创建并挂载；必要时在系统内完成一次性创建与格式化。
- NAND：`dmesg | grep -i ubi` 观察 UBI 初始化是否正常（容量与布局匹配）。
- 出现异常：回到 WebUI 重新对齐三件套（或 FIP），必要时走 TFTP/串口救援。

—

## 快速总览：硬件版本 × 固件类型 × 所需文件与下载位置

目的：一眼看清“你的介质（eMMC/NAND）当前路线（ITB/BIN）”需要的文件与下载入口，避免混刷。

- eMMC → ITB（all‑in‑FIT，刷 `.itb`）
  - 需要文件：`...-emmc-gpt.bin`、`...-emmc-preloader.bin`、`...-emmc-fip.fit/ bin`、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
  - 下载位置：
    - U‑Boot 三件套（GPT/BL2/FIP）：`https://drive.wrt.moe/uboot/mediatek/`
    - ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
    - OpenWrt 稳定版（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

- eMMC → BIN（custom U‑Boot layout，单分区，刷 `.bin`）
  - 需要文件：`mt7981-cmcc_rax3000m-emmc-gpt.bin`、`mt7981-cmcc_rax3000m-emmc-bl2.bin`、`mt7981-cmcc_rax3000m-emmc-fip.bin`、目标 `...-squashfs-sysupgrade.bin`
  - 下载位置：
    - U‑Boot 三件套（BIN 路线）：`https://drive.wrt.moe/uboot/mediatek/`
    - 社区 BIN 固件构建（参考）：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`

- NAND → ITB（主线路线，刷 `.itb`）
  - 需要文件：`...-nand-preloader.bin`（BL2）、`...-nand-fip.fit/bin`（FIP/U‑Boot）、`initramfs-recovery.itb`、`squashfs-sysupgrade.itb`
  - 下载位置：
    - U‑Boot 三件套（NAND FIT）：`https://drive.wrt.moe/uboot/mediatek/`
    - ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
    - OpenWrt 稳定版（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

- NAND → BIN（uboot/ubootmod，刷 `.bin`）
  - 需要文件：支持 BIN 的 FIP（如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）、目标 `...-squashfs-sysupgrade.bin`
  - 下载位置：
    - FIP（支持 BIN）：`https://github.com/hanwckf/bl-mt798x/releases`
    - BIN 固件：自建或社区构建（需与所选 uboot/ubootmod 布局匹配）

注意：严禁混刷。“`emmc-*` 仅用于 eMMC”，“`nand-*` 仅用于 NAND”。BIN/ITB 路线的 U‑Boot/FIP 必须与目标固件格式一致。

## eMMC（算力版，64GB）

### 升级到 ITB 路线（all‑in‑FIT）
目的：让 U‑Boot 接受 `.itb` 并用 WebUI 刷 ITB 固件。

准备文件（建议从官方镜像库与选择器获取）：
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`（GPT）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`（BL2/Preloader）
- `mt7981-cmcc_rax3000m-emmc-fip.fit` 或 `mt7981-cmcc_rax3000m-emmc-fip.bin`（FIP/U‑Boot，文件名随发布源而异）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb`（先刷此）
- `immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-squashfs-sysupgrade.itb`（系统内再升级到此）

下载页面与示例：
- GPT/BL2/FIP（eMMC all‑in‑FIT）：`https://drive.wrt.moe/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`emmc` 的 `gpt.bin`、`preloader.bin`、`fip.fit/bin`）
- ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`（下载 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`）

WebUI 操作顺序：
1. 浏览器进 `http://192.168.1.1/gpt.html` 上传并刷入 `...-emmc-gpt.bin` → 完成后重启回 U‑Boot。
2. 进入 `http://192.168.1.1/bl2.html` 上传并刷入 `...-emmc-preloader.bin` → 完成后重启回 U‑Boot。
3. 进入 `http://192.168.1.1/uboot.html` 上传并刷入 `...-emmc-fip.fit（或 .bin）` → 完成后重启回 U‑Boot。
4. 打开固件上传页面，先刷 `initramfs-recovery.itb`，进入临时系统，再在系统内升级到 `squashfs-sysupgrade.itb`。

备注：该路线对应 eMMC 的 all‑in‑FIT 分区；默认不创建最后约 56GB 的数据分区，首次进入系统后需一次性用 `cfdisk /dev/mmcblk0` 新建并 `mkfs.ext4` 格式化（只需一次，后续固件自动挂载）。

### 降级到 BIN 路线（custom U‑Boot layout，单分区）
目的：让 U‑Boot 接受 `.bin` 并用 WebUI 刷 BIN 固件。

准备文件（官方镜像库）：
- `mt7981-cmcc_rax3000m-emmc-gpt.bin`（单分区 GPT）
- `mt7981-cmcc_rax3000m-emmc-bl2.bin`（单分区 BL2）
- `mt7981-cmcc_rax3000m-emmc-fip.bin`（单分区 FIP/U‑Boot，支持 BIN + WebUI）
- BIN 固件：例如 `immortalwrt-mediatek-mt7981-cmcc_rax3000m-emmc-squashfs-sysupgrade.bin`（来自社区构建或自建）

下载页面与示例：
- GPT/BL2/FIP（eMMC 单分区 BIN 路线）：`https://drive.wrt.moe/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`emmc` 与 `gpt.bin`、`bl2.bin`、`fip.bin` 的文件）
- BIN 固件（eMMC 单分区）：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`

WebUI 操作顺序：
1. `gpt.html` → 上传并刷入单分区 `...-emmc-gpt.bin` → 重启回 U‑Boot。
2. `bl2.html` → 上传并刷入单分区 `...-emmc-bl2.bin` → 重启回 U‑Boot。
3. `uboot.html` → 上传并刷入单分区 `...-emmc-fip.bin` → 重启回 U‑Boot。
4. 固件上传页面 → 刷入 `.bin`（如 `...-squashfs-sysupgrade.bin`）。

备注：首次进入“单分区”后，同样需要一次性创建并格式化 eMMC 的大数据分区（约 56GB），后续无需重复。

—

## NAND（普通版，128MB）

### 重要说明（避免混淆）
- 你常见的三件套命名：`mt7981-cmcc_rax3000m-nand-fip-fit.bin / -expand.bin / -stock.bin`，均为 FIT 路线的 FIP，目标是刷 `.itb` 固件（不是 BIN）。
- 若希望刷 `.bin`，请改用支持 BIN 的 FIP，如 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（不死 U‑Boot/ubootmod 路线）。

### 升级到 ITB 路线（OpenWrt U‑Boot layout）
目的：让 U‑Boot 接受 `.itb` 并用 WebUI 刷 ITB 固件。

准备文件（官方镜像库与选择器）：
- `openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（BL2/Preloader，具体命名视镜像而定）
- `mt7981-cmcc_rax3000m-nand-fip.fit/bin`（FIP/U‑Boot，带 WebUI + FIT 支持）
- ITB 固件：`...-initramfs-recovery.itb` 与 `...-squashfs-sysupgrade.itb`

下载页面与示例：
- BL2/FIP（NAND ITB 路线）：`https://drive.wrt.moe/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`nand` 的 `preloader.bin` 与 `fip.fit/bin`，或 `-expand.bin`/`-stock.bin` 变体）
- ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m` 或 `https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`

WebUI 操作顺序：
1. `bl2.html` → 上传并刷入 NAND Preloader → 重启回 U‑Boot。
2. `uboot.html` → 上传并刷入 NAND FIP（FIT 支持）→ 重启回 U‑Boot。
3. 固件上传页面 → 先刷 `initramfs-recovery.itb`，进入系统，再升级到 `squashfs-sysupgrade.itb`。

布局说明：NAND 有 `stock/uboot/ubootmod` 多种分区布局（UBI 容量不同），所刷 ITB 固件需与当前布局匹配。

### 降级到 BIN 路线（uboot / ubootmod）
目的：让 U‑Boot 接受 `.bin` 并用 WebUI 刷 BIN 固件。

准备文件：
- `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`（FIP/U‑Boot，常用于恢复/启用 BIN 支持）→ `https://github.com/hanwckf/bl-mt798x/releases`
- BIN 固件：如 `immortalwrt-...-cmcc_rax3000m-nand-ubootmod-squashfs-sysupgrade.bin`（与你选择的 `uboot/ubootmod` 布局一致）
 - 可选（仅在需要时更换 BL2）：`openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（兼容的 BL2/Preloader）

下载页面与示例：
- FIP 固件（恢复 BIN 支持）：`https://github.com/hanwckf/bl-mt798x/releases`（在对应 release 资产中获取 `mt798x-uboot-...-fip.7z`，解压得到 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）
- BIN 固件（NAND 布局匹配）：`https://downloads.immortalwrt.org/` 或第三方构建，注意选择 `nand-uboot`/`nand-ubootmod` 的 `squashfs-sysupgrade.bin`
 - BL2/Preloader（若需要更换）：`https://drive.wrt.moe/uboot/mediatek/`（查找 `cmcc_rax3000m` 的 `nand-preloader.bin`）

是否需要刷 BL2？（给出明确判断）
- 默认结论：切到 BIN 路线通常“仅替换 FIP”即可，不需要更换 BL2。
- 触发更换 BL2 的典型信号：
  - 写入 BIN‑FIP 后无法进入 U‑Boot WebUI（串口停在早期初始化或反复重启）。
  - WebUI 能出现但刷入 `.bin` 后立即失败，且串口提示 DDR/早期初始化异常。
  - 设备仍使用较老或 OEM 的 BL2，与所选 FIP 路线存在不兼容历史。
- 如何确认分区名：`cat /proc/mtd`，记录 `BL2` 或 `Preloader`、`FIP` 的实际分区名（以下命令中的分区名需按你的设备替换）。

更换 BL2 的步骤（仅在上述信号出现时执行）：
1. 将 `...-nand-preloader.bin` 上传到路由器的 `/tmp/`。
2. 执行写入（示例，分区名以实际为准）：
   - `mtd write /tmp/openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2`
3. 重启回 U‑Boot，确认能进入 WebUI；如仍异常，再次写入 BIN‑FIP 并重启：
   - `mtd write /tmp/mt7981_cmcc_rax3000m-fip-fixed-parts.bin FIP`
4. WebUI 页面应能选择并接受 `.bin` 固件。
注意：若 MTD 设备只读，可安装 `kmod-mtd-rw` 后解锁再写入；刷错 BL2 风险更高，务必串口在线或准备 TFTP 恢复方案。

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

—

## 快速文件清单示例（命名以官方/社区实际发布为准）
- eMMC → ITB 路线：
  - `...-emmc-gpt.bin`、`...-emmc-preloader.bin`、`...-emmc-fip.fit/bin`、`...-initramfs-recovery.itb`、`...-squashfs-sysupgrade.itb`
- eMMC → BIN 路线：
  - `...-emmc-gpt.bin`、`...-emmc-bl2.bin`、`...-emmc-fip.bin`、`...-squashfs-sysupgrade.bin`
- NAND → ITB 路线：
  - `...-nand-preloader.bin`、`...-nand-fip.fit/bin`（或 `-expand.bin`/`-stock.bin`）、`...-initramfs-recovery.itb`、`...-squashfs-sysupgrade.itb`
- NAND → BIN 路线：
  - `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`、`...-nand-uboot/ubootmod-squashfs-sysupgrade.bin`

—

## 参考与来源
- U‑Boot 镜像库（含 cmcc_rax3000m eMMC/NAND 三件套）：`https://drive.wrt.moe/uboot/mediatek/`
- eMMC 单分区路线与操作说明：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc`
- eMMC 单分区社区构建（闭源驱动路线）：`https://github.com/kkstone/Actions-RAX3000M-EMMC`
- NAND 布局与 FIP（BIN 支持）参考：`https://github.com/hanwckf/bl-mt798x/releases`、`https://github.com/ytalm/openwrt-rax3000m-nand`
- OpenWrt 对 RAX3000M 的支持说明（含 eMMC/NAND 指南与 all‑in‑FIT 路线）：`https://github.com/openwrt/openwrt/pull/13513`
- OEM 获取 SSH 权限与免拆流程（示例教程）：知乎 `CMCC RAX3000M算力版EMMC刷机OpenWrt教程＆玩机报告`（https://zhuanlan.zhihu.com/p/696434968）
- NAND 获取 SSH 与 FIP 写入示例（社区博客）：`https://hjfrun.com/note/rax3000m-nand`
- OEM 解密配置与备份/刷机示例（GitHub 整理贴）：`https://github.com/fanmaomao/CMCC_RAX3000M`
- eMMC dd 三件套与路线选择讨论（知乎教程）：`https://zhuanlan.zhihu.com/p/688078113`
