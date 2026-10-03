# Recovery 显示与 USB ADB 调试

## Recovery 黑屏线索

用户修复历史：

- `d79c231`：在 recovery 初始化时启用 blank/unblank。
- [73e2b6f](https://github.com/celeron633/android_device_xiaomi_nabu/commit/73e2b6fb7606897a456405bcf685121cc394dfa1)：将 BoardConfig 变量迁移为 `ro.recovery.ui.blank_unblank_on_init=true`。

LOS 20 当前 `bootable/recovery/recovery_ui/screen_ui.cpp` 会读取此属性；启用后，在图形初始化完成时调用 `gr_fb_blank(true)` 与 `gr_fb_blank(false)`。DRM 后端因此先禁用 CRTC，再重新启用 CRTC 和 framebuffer。

旧 dev-harsh1998 lineage-20 基线和初版拆分树都没有此设置。显示从 bootloader 交给 recovery 时没有完成所需的重新初始化，是与既有修复吻合的黑屏原因推断；并非已用实机日志证明的唯一原因。该属性现已加回 nabu/vendor.prop，并确认进入生成的 recovery/prop.default。

## 调试配置

默认 `breakfast nabu` 选择 userdebug。userdebug/eng 构建：

- `WITH_ADB_INSECURE=true` 在继承 Lineage 公共产品前设置，使生成的 `ro.adb.secure=0`。
- `ro.adb.secure.recovery=0`，recovery 无需屏幕授权。
- `persist.sys.usb.config=adb`。
- `init.nabu.debug.rc` 只在调试构建安装到 `/system/etc/init/`；在 `on init` 准备 configfs 和 ADB FunctionFS，选择 USB ADB 并请求启动 adbd。
- 持久属性加载后和 Qualcomm boot USB 脚本执行后，重新选用 ADB，避免旧 /data 设置或脚本清空配置。
- recovery 在 `post-fs`、FunctionFS 准备完成后启动 ADB，早于 recovery UI 初始化。

`user` 构建配置已核对，继续使用 `ro.adb.secure=1`。没有修改 SELinux 策略或普通系统的 ro.secure。调试结束后可撤回单独的 ADB 调试提交，保留 recovery 显示修复。

## 启动时机边界

正常 Android 的 adbd 是 APEX 服务。LOS 20 init 会把早期启动请求排队，待 APEX 激活和服务配置加载完成后执行。因此不需要等 Android 桌面或授权 UI，但无法覆盖 kernel/first-stage-init 崩溃，或正常系统卡在 APEX 可用之前的情况。

recovery 使用自身 ramdisk 的 adbd，没有这一 APEX 等待；当前 post-fs 启动点也不依赖 recovery UI 成功显示。后续菜单仍可切换 USB 到 sideload/fastbootd，没有添加持续强制切回 ADB 的触发器。

recovery 属性和 init 文件需要进入重新生成的 vendor_boot recovery 资源；正常系统调试脚本和属性在 system 镜像中。这里只生成了属性和 init 验证产物，没有编译完整 boot/vendor_boot 镜像或刷机。

## 实机取日志

```bash
adb wait-for-device
adb shell getprop ro.adb.secure
adb shell getprop ro.adb.secure.recovery
adb shell getprop ro.recovery.ui.blank_unblank_on_init
adb shell getprop sys.usb.state
adb root
adb wait-for-device
adb shell dmesg > nabu-dmesg.log
adb logcat -b all -d > nabu-logcat.log
adb pull /sys/fs/pstore nabu-pstore
adb pull /tmp/recovery.log nabu-recovery.log
```

`/tmp/recovery.log` 为 recovery 场景。重点检查 DRM/DSI、panel、backlight、CRTC、图形初始化和 recovery 是否崩溃；USB 未出现时检查 configfs、UDC 和 adbd 的 init 日志。

## 本次验证（2026-10-03）

- breakfast nabu、m nothing：通过。
- host_init_verifier、nabu-debug-init、nabu_init.recovery.qcom.rc、recovery/root/prop.default 的定向构建：通过。
- 生成的 system/build.prop：ro.adb.secure=0、ro.adb.secure.recovery=0、persist.sys.usb.config=adb。
- 生成的 recovery/root/prop.default：上述属性及 ro.recovery.ui.blank_unblank_on_init=true。
- user 配置：WITH_ADB_INSECURE 为空，ro.adb.secure=1，无 recovery 认证关闭属性。
- 尚未确认实机 recovery 显示和 USB 连接行为。

日志目录：`/tmp/nabu-debug-check/`。

## 首次正常系统启动失败（2026-10-03）

输入日志：`/home/dengxh/nabu_debug/`。console-ramoops-0 显示逻辑分区挂载后进入 second-stage init，apexd bootstrap 已执行，之后持续等待 `android.system.keystore2.IKeystoreService/default`；pmsg 同时出现等待 `android.hardware.keymaster@4.0::IKeymasterDevice/default` 的记录。这证明启动被加密服务依赖阻塞，但尚不能区分服务启动失败、崩溃或固件通信问题。4.1 Keymaster 也实现 4.0 接口，不能仅凭等待日志中的 4.0 就修改 manifest。

原 console 中大量 init/apexd 日志被 `/dev/kmsg` 限流丢弃，pmsg 的早期日志被 sscrpcd 重复错误覆盖。userdebug/eng 的 kernel cmdline 增加 `printk.devkmsg=on`，保留早期 init 与服务错误；user 构建不添加。此改动仅增强取证，尚未修复或实机验证启动问题。

header v3 的内核命令行位于 vendor_boot，而非 boot；重新生成的日志 vendor_boot 可以单独刷入当前槽位，不需要替换 dtbo 或重编完整 ROM。尝试启动约 15 秒后直接强制重启进 recovery，尽快取回 pstore，避免重复启动覆盖日志：

```bash
adb pull /sys/fs/pstore nabu-pstore-verbose
adb shell dmesg > nabu-recovery-dmesg-verbose.log
```

下一轮重点检查 Keymaster、qseecomd、keystore2 的启动/退出记录，以及 vold 和 mount_all 的阻塞位置。

定向构建 bootimage 和 vendorbootimage 均通过。解包确认 `vendor_boot` 命令行含 `printk.devkmsg=on`，boot/vendor_boot 的嵌入 AVB hash 校验通过；内核与已生成完整 OTA 的 boot 内核 SHA256 相同。测试镜像和说明位于 `/home/dengxh/nabu_debug/boot-verbose/`，本次只需刷入其中的 `vendor_boot-debug.img`。
