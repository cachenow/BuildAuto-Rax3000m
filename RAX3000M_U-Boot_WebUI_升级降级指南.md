# RAX3000M U-Boot WebUI 升级/降级指南（NAND/eMMC）

面向 CMCC RAX3000M 的 eMMC（算力版）与 NAND（普通版），本指南提供“仅通过 U-Boot WebUI”完成从支持 BIN 的 U-Boot 切换到支持 ITB（FIT）的 U-Boot，或反向降级回支持 BIN 的 U-Boot，并最终通过 WebUI 刷入系统固件（`.bin` 或 `.itb`）。

指南要点：
- U-Boot WebUI 变种通常提供专用页面：`gpt.html`（GPT）、`bl2.html`（Preloader/BL2）、`uboot.html`（FIP/U‑Boot 本体），以及固件上传页面（接受 `.bin` 或 `.itb`）。
- 选择“ITB 路线”或“BIN 路线”时，必须对应刷入匹配的 GPT/BL2/FIP 套件；完成后，固件页面才会接受你想要的格式。
- 全程通过浏览器完成，不需要命令行（前提是你的 U‑Boot WebUI包含上述页面）。

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
- U‑Boot 三件套（GPT/BL2/FIP）官方镜像库：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`
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
- U‑Boot 三件套目录（GPT/BL2/FIP）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`
- ImmortalWrt 固件选择器（ITB）：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`
- OpenWrt 固件目录（ITB 备用）：`https://downloads.openwrt.org/releases/23.05.4/targets/mediatek/filogic/`
- eMMC BIN 社区构建：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`
- NAND BIN FIP 发布页：`https://github.com/hanwckf/bl-mt798x/releases`

说明：ImmortalWrt 的下载站可能出现人机验证（Cloudflare），请耐心等待或更换浏览器；文件命名随发布版本略有差异，按下文的“示例文件名与下载页面”匹配设备介质与路线即可。

—

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
- GPT/BL2/FIP（eMMC all‑in‑FIT）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`emmc` 的 `gpt.bin`、`preloader.bin`、`fip.fit/bin`）
- ITB 固件：`https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek/filogic&id=cmcc_rax3000m`（下载 `initramfs-recovery.itb` 与 `squashfs-sysupgrade.itb`）

WebUI 操作顺序：
1. 浏览器进 `http://192.168.1.1/gpt.html` 上传并刷入 `...-emmc-gpt.bin` → 完成后重启回 U‑Boot。
2. 进入 `http://192.168.1.1/bl2.html` 上传并刷入 `...-emmc-preloader.bin` → 完成后重启回 U‑Boot。
3. 进入 `http://192.168.1.1/uboot.html` 上传并刷入 `...-emmc-fip.fit/bin` → 完成后重启回 U‑Boot。
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
- GPT/BL2/FIP（eMMC 单分区 BIN 路线）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`emmc` 与 `gpt.bin`、`bl2.bin`、`fip.bin` 的文件）
- BIN 固件（eMMC 单分区）：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc/releases`、`https://github.com/kkstone/Actions-RAX3000M-EMMC/releases`

WebUI 操作顺序：
1. `gpt.html` → 上传并刷入单分区 `...-emmc-gpt.bin` → 重启回 U‑Boot。
2. `bl2.html` → 上传并刷入单分区 `...-emmc-bl2.bin` → 重启回 U‑Boot。
3. `uboot.html` → 上传并刷入单分区 `...-emmc-fip.bin` → 重启回 U‑Boot。
4. 固件上传页面 → 刷入 `.bin`（如 `...-squashfs-sysupgrade.bin`）。

备注：首次进入“单分区”后，同样需要一次性创建并格式化 eMMC 的大数据分区（约 56GB），后续无需重复。

—

## NAND（普通版，128MB）

### 升级到 ITB 路线（OpenWrt U‑Boot layout）
目的：让 U‑Boot 接受 `.itb` 并用 WebUI 刷 ITB 固件。

准备文件（官方镜像库与选择器）：
- `openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin`（BL2/Preloader，具体命名视镜像而定）
- `mt7981-cmcc_rax3000m-nand-fip.fit/bin`（FIP/U‑Boot，带 WebUI + FIT 支持）
- ITB 固件：`...-initramfs-recovery.itb` 与 `...-squashfs-sysupgrade.itb`

下载页面与示例：
- BL2/FIP（NAND ITB 路线）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`（查找包含 `cmcc_rax3000m`、`nand` 的 `preloader.bin` 与 `fip.fit/bin`）
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

下载页面与示例：
- FIP 固件（恢复 BIN 支持）：`https://github.com/hanwckf/bl-mt798x/releases`（在对应 release 资产中获取 `mt798x-uboot-...-fip.7z`，解压得到 `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`）
- BIN 固件（NAND 布局匹配）：`https://downloads.immortalwrt.org/` 或第三方构建，注意选择 `nand-uboot`/`nand-ubootmod` 的 `squashfs-sysupgrade.bin`

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
  - `...-nand-preloader.bin`、`...-nand-fip.fit/bin`、`...-initramfs-recovery.itb`、`...-squashfs-sysupgrade.itb`
- NAND → BIN 路线：
  - `mt7981_cmcc_rax3000m-fip-fixed-parts.bin`、`...-nand-uboot/ubootmod-squashfs-sysupgrade.bin`

—

## 参考与来源
- U‑Boot 镜像库（含 cmcc_rax3000m eMMC/NAND 三件套）：`https://firmware.download.immortalwrt.eu.org/uboot/mediatek/`
- eMMC 单分区路线与操作说明：`https://github.com/AngelaCooljx/Actions-rax3000m-emmc`
- eMMC 单分区社区构建（闭源驱动路线）：`https://github.com/kkstone/Actions-RAX3000M-EMMC`
- NAND 布局与 FIP（BIN 支持）参考：`https://github.com/hanwckf/bl-mt798x/releases`、`https://github.com/ytalm/openwrt-rax3000m-nand`
- OpenWrt 对 RAX3000M 的支持说明（含 eMMC/NAND 指南与 all‑in‑FIT 路线）：`https://github.com/openwrt/openwrt/pull/13513`
