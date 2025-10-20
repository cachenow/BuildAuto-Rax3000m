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
sed -i "s/hostname='.*'/hostname='Rax3000M eMMC'/g" package/base-files/files/bin/config_generate
