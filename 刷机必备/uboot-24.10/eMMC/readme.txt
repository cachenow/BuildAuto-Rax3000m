目前ImmortalWrt24.10.0采用.itb 文件格式官方的也是，原来自己的U-Boot 是自动DHCP是不支持.itb 文件格式。参考crazy78的贴子自己摸索成功，现已把过程分享。
先到官网下载文件
EMMC-GPT.BIN
EMMC-PRELOADER.BIN
还有KERNEL 和 SYSUPGRADE 这俩个ITB名固件文件
ImmortalWrt 固件
https://firmware-selector.immortalwrt.org/?version=24.10.0&target=mediatek%2Ffilogic&id=cmcc_rax3000m
路由器按复位键进入UBOOT，如果没有自动DHCP要改IP地址192.168.1.2，浏览器输入
192.168.1.1/gpt.html，选择immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-gpt（EMMC-GPT.BIN）刷机，重启进UBOOT，浏览器输入
192.168.1.1/bl2.html，选择EMMC-immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-emmc-preloader（PRELOADER.BIN刷机，重启进UBOOT，浏览器输入http://192.168.1.1/uboot.html，提前下载这个UBOOT刷机（https://drive.wrt.moe/uboot/mediatek/mt7981-cmcc_rax3000m-emmc-fip-fit.bin）
之后就用这个新的UBOOT刷ITB文件。先刷immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-initramfs-recovery，进系统再升级immortalwrt-24.10.0-mediatek-filogic-cmcc_rax3000m-squashfs-sysupgrade
如果要降级就下载降级的ITN文件刷机就可以了。官方的OPENWRT也是可以刷的要ITB格式
刷机有风险，请自行承担风险。我是没问题。切记不要下错文件。

注意！！！！！Uboot用这里的！！！！！！！！！！！
https://drive.wrt.moe/uboot/mediatek