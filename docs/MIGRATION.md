# nabu：LineageOS 20 / sm8150-common

源码目录：/home/dengxh/android2/lineage。原 /home/dengxh/android/lineage 设备树未修改。

## 当前分工

| 实现/数据 | 位置 |
| --- | --- |
| SoC 产品、公共 HAL、通用启动脚本与策略 | sm8150-common / hardware/xiaomi |
| 可配置的平板设置 UI、多语言资源、hwcontrol AIDL 服务 | sm8150-common/tablet |
| Power HAL | hardware/xiaomi 的官方 Xiaomi libperfmgr 实现 |
| 功能开关、音效 UUID、热策略节点/值、刷新率及图标 | nabu/configs/tablet-settings |
| CPU/GPU/总线 hint 节点和参数 | nabu/configs/powerhint.json |
| 笔/键盘/双击唤醒节点路径 | nabu/vendor.prop |
| 硬件节点标签、访问权限和 init 所有权 | nabu/sepolicy / rootdir |
| 虚拟 A/B、vendor_boot recovery、fstab、设备身份、四扬声器、overlay、Wi-Fi 差异 | nabu |

common 的设置实现没有写死 nabu 路径或刷新率。设备通过一个资源 android_library 提供配置，继承默认库后按需覆盖。节点通过只读 ro.vendor.sm8150.tablet.* 属性传给服务；实际 sysfs 标签/权限仍由设备定义。

TARGET_USES_DEVICE_ROOTDIR 仅禁用被设备覆盖的 common 启动模块，公共脚本、库与 namespace 正常复用。手机默认实现不选入 tablet namespace 或 tablet SELinux。

TARGET_POWER_HINT_CONFIG 指向设备 JSON，手机未设置时仍使用原 common JSON。nabu 使用旧设备树中已有的 nabu hint 数据，并采用设备自己的交互持续时间设置。此次替换了旧 Power HAL，功耗和性能行为需要正常 Android 系统实机验证。

## 基线

设备与 common/vendor/hardware 的上游基线仍见 [upstream-lock.json](upstream-lock.json)。common、nabu DT 和 nabu vendor 的适配提交分别在本地 nabu-los20 分支；common 所需的本地整合提交也单独记录在锁定文件中。必须使用包含 shared tablet 支持的 common checkout。完整实现通过 Git 提交维护，原先的独立小补丁已经移除，不再需要 patches/ 目录。发布可复用的 manifest 时，应指向包含该整合提交的 common fork。

官方内核没有 lineage-20 分支，lineage-19.1 缺少 nabu 支持。使用官方 lineage-22.2 的 Linux 4.14.356，用户空间为 Android 13。内核与 boot/dtbo/vendor_boot 已实际编译，用户确认 recovery 启动成功；完整 Android 系统仍需实机验证。

common blobs 使用 TheMuppets lineage-20。nabu 专有清单保留硬件差异，不重复 common 文件；libqti-perfd-client 改为使用 common 的源码实现。音频仍使用 nabu 的四扬声器 HAL及其固件/校准。

## 构建

```bash
cd /home/dengxh/android2/lineage
source build/envsetup.sh
breakfast nabu
mka bacon -j8
```

定向检查公共实现：

```bash
m -j8 XiaomiTabletSettings custom.hardware.hwcontrol-service android.hardware.power-service.xiaomi-libperfmgr selinux_policy
```

静态检查：

```bash
get_build_var PRODUCT_COPY_FILES > /tmp/nabu-copy-files.txt
python3 device/xiaomi/nabu/tools/validate-tree.py --copy-files /tmp/nabu-copy-files.txt --check-elf-dependencies
```

只提取设备 blobs：

```bash
bash device/xiaomi/nabu/extract-files.sh /path/to/nabu/dump
bash device/xiaomi/nabu/setup-makefiles.sh
```

共享 blobs 使用锁定的 common checkout，避免由单一 nabu dump 替换公共固定版本。提取脚本继续修复 nabu audio/offload 库的名称和依赖。

## 历史与验证

以原 43eca20 为终点的 616 个旧提交已压成一个根快照；之后的移植、recovery 修复、ADB 调试、清理与公共实现整合分别提交。原始历史及整合前的仓库快照在源码树外 `/home/dengxh/android2/nabu-dt-backups/` 的 Git bundle 中保留，上游远程分支用于溯源。

此前从 337 清理到 278 个文件，本次进一步把可配置公共实现移入 common，设备树主要保留数据和硬件差异。当前验证结果见 [VALIDATION.md](VALIDATION.md)；recovery/ADB 调试说明见 [DEBUGGING.md](DEBUGGING.md)。

## 大陆网络验证地址

nabu 的 NetworkStackOverlayNabu 安装在 product 分区，针对 com.android.networkstack 的 NetworkStackConfig 配置 HTTP、HTTPS 和 fallback URL。HTTP 使用用户指定的 http://connect.rom.miui.com/generate_204，HTTPS 使用 https://connect.rom.miui.com/generate_204；同时设置单 URL 和多 URL 数组，避免其他设置或默认数组仍选到 Google 地址。保留 HTTPS 验证与 captive portal 检测本身，不改公共 NetworkStack 源码。

这是 NetworkStack 的资源配置，优先级高于 Settings.Global URL 设置；不需要通过 SettingsProvider 初始化数据库或清除用户数据。刷入新 ROM 并重启/重新连接 Wi-Fi 后，可查看生效配置：

```bash
adb shell cmd overlay lookup com.android.networkstack com.android.networkstack:string/config_captive_portal_http_url
adb shell cmd overlay lookup com.android.networkstack com.android.networkstack:string/config_captive_portal_https_url
```

本机 HTTP/HTTPS 的 HEAD 和 GET 请求均返回 204、空响应体；五项资源通过 NetworkStackConfig product overlayable 策略核对，overlay 定向构建通过，aapt2 确认包内没有 Google 探测地址。大陆实际网络和需要网页认证的 Wi-Fi 仍需实机确认。
