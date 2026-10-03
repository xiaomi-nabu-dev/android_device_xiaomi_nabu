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
- `init.nabu.debug.rc` 只在调试构建安装到 `/system/etc/init/`；在 `on init` 准备 configfs 目录并保持 USB 配置为 none，在 `on boot` 的默认 APEX namespace 中选择 USB ADB 并启动 adbd。FunctionFS 挂载由已有 Qualcomm USB init 负责。
- 持久属性加载后只记录 persist.sys.usb.config=adb；到 boot 再选用 USB ADB，避免在 APEX namespace 就绪之前间接触发启动。
- recovery 在 `post-fs`、FunctionFS 准备完成后启动 ADB，早于 recovery UI 初始化。

`user` 构建配置已核对，继续使用 `ro.adb.secure=1`。没有修改 SELinux 策略或普通系统的 ro.secure。调试结束后可撤回单独的 ADB 调试提交，保留 recovery 显示修复。

## 启动时机边界

正常 Android 的 adbd 是 APEX 服务。LOS 20 在 perform_apex_config 中先释放排队服务，随后才完成默认 namespace 的 linker 配置；早期请求因此可能让 adbd 永久标记为 bootstrap 服务，看不到非 bootstrap 的 adbd APEX。当前在 boot 阶段首次启动 adbd，仍早于桌面可用，也无需授权 UI，但无法覆盖 kernel/first-stage-init 或 APEX 就绪之前的崩溃。

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

## 增强日志定位到缺失共享库

更新后的 `/home/dengxh/nabu_debug/nabu-pstore/` 显示 Keymaster 两次启动均退出 status 1，Gatekeeper 也退出 status 1。pmsg 明确记录 Gatekeeper 的 `dlopen` 失败：`libqcbor.so` 不存在。Keymaster 的 `libqtikeymaster4.so` 同样通过 DT_NEEDED 依赖该库。common 上游包含该 blob，但 nabu 的手机功能过滤列表误将它排除。keystore2 因 Keymaster 不可用持续等待，vold 的数据分区加密初始化因此不能完成，后面的 APEX/ADB/动画阶段没有到达。

修复限定在 nabu 的 `common-vendor.mk`：恢复 libqcbor 及依赖审计发现的另外 11 个共享库；恢复 nabu init 仍声明的 pd-mapper 和 qrtr-ns 程序。库按保留组件的直接与传递依赖确定，继续从 common 取文件，不在 nabu vendor 中复制。

`tools/validate-tree.py --copy-files /tmp/nabu-fixed-copy-files.txt --check-elf-dependencies` 检查通过：1509 个复制目的地、971 项保留 blob；它检查显式过滤的库是否仍被保留 blob 的 DT_NEEDED 引用。此检查不涵盖 dlopen 字符串、固件兼容性或实机运行。正常系统启动仍需重新构建完整 ROM 后验证；本次依赖修复不会进入仅刷入 vendor_boot 的镜像。

14 项恢复文件的定向构建通过，安装输出与 common blob 逐字节一致。尚未重新生成完整 ROM ZIP 或验证正常系统开机。

## F2FS casefold 导致 init_user0_failed

下一轮输入：`/home/dengxh/nabu_debug/nabu-pstore-verbose/`。Keymaster 4.1 和 Gatekeeper 已注册，证实恢复共享库后原启动阻塞已解除。userdata 初始化时，vold 成功创建带 casefold 的 F2FS，但内核反复报告 `Filesystem with casefold feature cannot be mounted without CONFIG_UNICODE`。`/data` 没有挂载，后续目录创建和 APEX 解压失败；init 最终报告 `Exec service failed, status 25: Rebooting into recovery, reason: init_user0_failed`。

官方 sm8150 手机 defconfig 未启用 UNICODE。nabu 的 BoardConfig 通过 Lineage 原生 `KERNEL_CONFIG_OVERRIDE := CONFIG_UNICODE=y` 启用它，避免修改公共内核源码或其他设备的配置；构建会在基础片段合并后运行 oldconfig。保持现有 F2FS、casefold 和加密配置，仅重编 boot 中的内核。无需为这个修复重新格式化 userdata，也无需替换 dtbo/vendor_boot。实际启动结果仍需刷入新 boot 后确认。

`m -j8 bootimage` 成功（4 分 58 秒）；生成 `.config` 确认 CONFIG_UNICODE=y，System.map 包含 utf8_load/utf8_casefold，解包确认新内核与旧 OTA 不同，嵌入 AVB hash 校验通过。测试镜像位于 `/home/dengxh/nabu_debug/boot-casefold/boot.img`，仅需更新当前槽位的 boot；正常系统开机仍待实机验证。

## 系统 ADB 时机修复与 Wi-Fi panic

实机已进入系统。Wi-Fi 取证文件实际位于 `/home/dengxh/nabu_debug/nabu-pstore-wifi/pstore/`；父目录中的两份文件仍是旧日志。新日志反复显示 adbd 在 APEX 已挂载后执行路径不存在；init 的 Service::Start 会把首次在默认 namespace ready 之前启动的服务永久标记为 bootstrap，属于此前早期 ADB 请求的时机错误。删除 init 阶段的 adbd/USB adb 请求、持久属性加载阶段仅写 persist 属性，到 boot 再启动，避免该错误；同时删除重复 FunctionFS 挂载。

`m nabu-debug-init`、host_init_verifier 和 recovery 应用脚本的 bash 语法检查通过。`tools/apply-adb-recovery-fix.sh` 可在 recovery 将新 rc 写入当前槽位的 system，不修改 userdata 设置；写入前备份原文件并尽量恢复只读挂载。运行包位于 `/home/dengxh/nabu_debug/adb-recovery-fix/`。当前主机未连接到设备，尚未执行恢复脚本或验证系统 ADB。若找不到当前逻辑 system 设备，应先通过 recovery 的挂载 system 功能创建映射。

Wi-Fi HAL 写驱动状态返回 Invalid argument；随后内核在约 48 秒记录 `Fatal error on modem!`、`Kernel panic - not syncing: subsys-restart: Resetting the SoC - modem crashed.`。这证明有真实的子系统 panic，尚未证明是 Wi-Fi 驱动本身、固件或配套服务缺失导致。本次不修改重启策略或掩盖 panic；先恢复正常系统 ADB 以便收集实时日志。
