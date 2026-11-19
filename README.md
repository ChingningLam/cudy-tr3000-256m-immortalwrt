# Cudy TR3000 v1 (256 MB) ImmortalWrt

为 Cudy TR3000 v1 256 MB 版本构建带 MediaTek HNAT 的 ImmortalWrt 固件。源码使用 [`tfnhui/immortalwrt-mt798x-25.12`](https://github.com/tfnhui/immortalwrt-mt798x-25.12) 的 `25.12` 滚动分支，导入 MediaTek OpenWrt Feeds 补丁，并基于 ImmortalWrt 25.12 系列源码。

## 固件功能

- 默认管理地址：`192.168.6.1`
- 默认主机名：`Cudy-TR3000`
- 默认 LuCI 主题：Aurora，预装 Aurora 设置插件并默认使用下拉菜单导航
- 集成 OpenClash 及其 nftables/TUN 依赖、UA3F、Bandix、UPnP
- 支持 USB CDC/RNDIS 网卡、Realtek RTL8152/8153 和 ASIX AX88179 外接网卡
- 启用 MediaTek HNAT 内核驱动，并包含 `hnat-detect`

当前 25.12 上游设备树不再导出旧版 `/sys/class/gpio/modem_power` 节点，因此本固件不承诺通过该路径控制 USB 供电。

## 获取固件

在本仓库的 **Releases** 页面下载对应版本的 `sysupgrade.bin`。刷写前请确认设备型号、硬件版本和当前分区布局与固件匹配，并保留可恢复的原厂固件。

## 构建

在 GitHub 仓库的 **Actions → OpenWrt Builder 256M → Run workflow** 手动启动构建。工作流也会由上游源码更新检查触发。成功后可在工作流 Artifacts 和 Releases 中下载固件。

构建配置位于 [`config/256m.config`](config/256m.config)，设备配置为 `cudy_tr3000-256mb-v1`。[`scripts/diy-part2.sh`](scripts/diy-part2.sh) 会启用 HNAT 内核选项；工作流在 `make defconfig` 后检查设备 profile 和 HNAT 配置，防止生成未启用加速的固件。源码仓库与分支位于 [构建工作流](.github/workflows/openwrt-builder-256m.yml)。

## 自定义

### 登录地址、主机名和密码

在 [`scripts/diy-part2.sh`](scripts/diy-part2.sh) 的 **User settings** 区修改：

- `LAN_IP`：路由器正常启动后的 LAN 管理地址，默认 `192.168.6.1`。
- `ROUTER_HOSTNAME`：设备主机名，默认 `Cudy-TR3000`。
- `ROOT_PASSWORD_HASH`：默认空字符串表示构建时不修改源码默认密码。要预设密码，先运行 `openssl passwd -6` 生成 SHA-512 密文，再把密文填到变量中；仓库里只保存密文，不保存明文密码。

`config/256m.config` 中的 `CONFIG_TARGET_PREINIT_IP` 是 failsafe/preinit 恢复地址，不是正常启动后的 LAN 管理地址。

### 其他构建选项

1. 在 `config/256m.config` 调整 OpenWrt 选项。
2. 在 `scripts/diy-part1.sh` 添加额外 feed 或第三方包仓库。
3. 在 `scripts/diy-part2.sh` 的 **User settings** 区修改登录地址、主机名和可选密码哈希，也可改设备默认值。
4. 提交到 GitHub 后，从 Actions 页面启动构建并检查日志及固件产物。

自定义脚本启用了严格错误处理，依赖的上游文件、设备配置或包目录缺失时会停止构建。HNAT 在本仓库上游配置中默认关闭；工作流显式启用它。MediaTek 文档说明外接设备的 HNAT 支持仍有限，尤其不要将此构建默认用于未验证的外接 WAN/LAN 设备。

## 致谢

- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [UA3F](https://github.com/SunBK201/UA3F)
- [Bandix](https://github.com/timsaya/luci-app-bandix)
- [luci-theme-aurora](https://github.com/eamonxg/luci-theme-aurora)

## 许可证

[MIT](LICENSE)，原始 Actions 构建脚本由 [P3TERX](https://p3terx.com) 提供。
