#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改默认IP
sed -i 's/192.168.1.1/192.168.200.1/g' package/base-files/files/bin/config_generate

# 更改主机名
sed -i "s/hostname='.*'/hostname='Rax3000M'/g" package/base-files/files/bin/config_generate

# 注入首启自动扩容脚本（仅 eMMC 上执行，使用 f2fs）
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-rax3000m-emmc-auto-expand << 'EOF'
#!/bin/sh

is_emmc() {
  [ -b /dev/mmcblk0 ] && [ -d /sys/block/mmcblk0 ]
}
is_rax3000m() {
  grep -qi 'rax3000m' /proc/device-tree/model 2>/dev/null
}
create_partition() {
  NEW=""
  LAST=$(ls /dev/mmcblk0p* 2>/dev/null | sed -n 's/^.*mmcblk0p\([0-9]\+\)$/\1/p' | sort -n | tail -n1)
  if [ -n "$LAST" ]; then
    NEW=$((LAST+1))
  else
    NEW=7
  fi
  if command -v sgdisk >/dev/null 2>&1; then
    sgdisk -n ${NEW}:0:0 -t ${NEW}:8300 -c ${NEW}:data /dev/mmcblk0
    echo 1 > /sys/class/block/mmcblk0/device/rescan 2>/dev/null || partprobe /dev/mmcblk0 2>/dev/null || true
    echo "$NEW"
    return 0
  fi
  # Fallback: parted（若存在）
  if command -v parted >/dev/null 2>&1; then
    parted -s /dev/mmcblk0 mkpart data ext4 0% 100%
    partprobe /dev/mmcblk0 2>/dev/null || true
    NEW=$(ls /dev/mmcblk0p* 2>/dev/null | sed -n 's/^.*mmcblk0p\([0-9]\+\)$/\1/p' | sort -n | tail -n1)
    echo "$NEW"
    return 0
  fi
  return 1
}

if is_emmc && is_rax3000m; then
  # 已挂载或已在 fstab 中则跳过
  grep -qE '\\s/opt\\s' /proc/mounts && exit 0
  uci -q show fstab | grep -q "target='/opt'" && exit 0

  PART_NUM=$(create_partition) || exit 0
  DEV="/dev/mmcblk0p${PART_NUM}"
  # 等待设备节点
  for i in $(seq 1 10); do [ -b "$DEV" ] && break; sleep 1; done

  # 格式化为 f2fs
  if command -v mkfs.f2fs >/dev/null 2>&1; then
    mkfs.f2fs -f "$DEV"
  else
    exit 0
  fi

  mkdir -p /opt
  uci -q add fstab mount
  uci -q set fstab.@mount[-1].target='/opt'
  uci -q set fstab.@mount[-1].device="$DEV"
  uci -q set fstab.@mount[-1].fstype='f2fs'
  uci -q set fstab.@mount[-1].enabled='1'
  uci commit fstab

  # 尝试立即挂载（首次开机即生效），失败不影响后续重启
  command -v block >/dev/null 2>&1 && block mount 2>/dev/null || true
fi

exit 0
EOF
chmod +x files/etc/uci-defaults/99-rax3000m-emmc-auto-expand

# 注入 eMMC 自动安装 Docker（Luci + Compose）脚本
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-rax3000m-emmc-docker-install << 'EOF'
#!/bin/sh

is_emmc() { [ -b /dev/mmcblk0 ] && [ -d /sys/block/mmcblk0 ]; }
is_rax3000m() { grep -qi 'rax3000m' /proc/device-tree/model 2>/dev/null; }

# 仅 eMMC 且当前机型执行
is_emmc || exit 0
is_rax3000m || exit 0

# 简单网络可达性检测（无网则跳过）
if ! ping -c1 -W2 openwrt.org >/dev/null 2>&1 && ! wget -q --spider https://downloads.openwrt.org 2>/dev/null; then
  exit 0
fi

opkg update || exit 0

# Docker 基础 + LuCI 管理
PKGS="dockerd docker luci-app-dockerman kmod-veth kmod-br-netfilter"
for p in $PKGS; do
  opkg info "$p" >/dev/null 2>&1 || continue
  opkg install "$p" || true
done

# 优先安装 Compose v2 插件；若不存在则尝试 v1（python）
COMPOSE_CANDIDATES="docker-compose-plugin docker-compose"
for c in $COMPOSE_CANDIDATES; do
  if opkg info "$c" >/dev/null 2>&1; then
    opkg install "$c" || true
    break
  fi
done

# 配置 Docker 数据目录到 /opt/docker
mkdir -p /etc/docker /opt/docker
cat > /etc/docker/daemon.json << 'JSON'
{
  "data-root": "/opt/docker",
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
JSON

# 使用 UCI（若存在）同步 data_root
if [ -f /etc/config/dockerd ]; then
  uci -q set dockerd.@docker[0].data_root='/opt/docker'
  uci -q commit dockerd
fi

# 开机自启并尝试立即启动
/etc/init.d/dockerd enable 2>/dev/null || true
/etc/init.d/dockerd start 2>/dev/null || true

# 验证 compose 是否可用（v2 或 v1 任一）
if docker compose version >/dev/null 2>&1; then
  logger -t init "docker compose v2 available"
elif docker-compose version >/dev/null 2>&1; then
  logger -t init "docker-compose v1 available"
else
  logger -t init "compose not available: please install docker-compose or plugin"
fi

exit 0
EOF
chmod +x files/etc/uci-defaults/99-rax3000m-emmc-docker-install
