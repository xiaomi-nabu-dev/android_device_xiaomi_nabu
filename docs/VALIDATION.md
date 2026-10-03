# 验证记录

2026-10-03，目标源码 `/home/dengxh/android2/lineage`，Android 13 / LineageOS 20.0，`lineage_nabu-userdebug`。

| 检查 | 结果 | 范围 |
| --- | --- | --- |
| breakfast nabu | 通过 | 产品选择、BoardConfig、依赖和基础变量解析 |
| m nothing | 通过，exit 0 | 完整 Soong / Make / 打包构建图生成 |
| NINJA_ARGS=-n brunch nabu | 通过，exit 0 | bacon 目标 151948 条计划构建步骤；未执行 ROM 编译或生成 OTA |
| m selinux_policy | 通过，exit 0 | 策略编译、neverallow、contexts 和 Treble 28.0–32.0 兼容性测试 |
| tools/validate-tree.py --copy-files … | 通过 | 439 项 nabu / 788 项 common blobs、XML、内核源文件和 1499 个复制目的地 |
| 内核配置合并与 olddefconfig | 通过 | sm8150-perf_defconfig + sm8150-common.config + nabu.config |
| git diff --check / bash -n | 通过 | 设备/common 补丁和提取脚本 |
| common 补丁 git apply --check | 通过 | [upstream-lock.json](upstream-lock.json) 对应的干净官方 common checkout |

内核 `.config` 已确认以下选项为 y：MACH_XIAOMI_NABU、TOUCHSCREEN_NT36523_HOSTDL_SPI、TOUCHSCREEN_COMMON、SND_SOC_CS35L41_V2、MSM_CSPL_V2、BATT_VERIFY_BY_DS28E16_NABU、IDT_P9418、BQ2597X_CHARGE_PUMP、CHARGER_LN8000、ANDROID_BINDERFS。

复制目的地检查仅保留了 AOSP / Lineage 基础产品中已有的两个声音文件重复目的地（Pyxis.ogg、Effect_Tick.ogg）；Android 按首个条目选择。没有 nabu/common 的 blob 交叉重复或设备文件复制冲突。

完整 ROM、内核镜像编译、刷机与实机测试尚未执行。上述结果不证明可以开机，也不覆盖相机、功耗、笔/键盘、充电或 OTA 的实际功能。

完整工具日志保存在本次会话的临时参考目录 `/tmp/nabu-los20-reference/`：breakfast.log、graph.log、brunch-dry-run.log、selinux.log、kernel-config.log；精确源提交见 [upstream-lock.json](upstream-lock.json)。

## 后续实机与清理验证

用户已确认 recovery 可以启动。内核以及 boot/dtbo/vendor_boot 已实际编译，测试包保存在 out/target/product/nabu/nabu-recovery-test-20261003.zip。

设备树清理后，m nothing、selinux_policy、6 个复用 common 的启动脚本定向构建、framework_compatibility_matrix.device.xml，以及 blob/XML/PRODUCT_COPY_FILES 检查通过。6 个安装脚本与 common 原文件逐字节一致，权限均为 0755。笔、键盘、双击唤醒、recovery 显示和调试 ADB 配置继续保留。

清理验证日志：/tmp/nabu-cleanup-check/。此前的完整 ROM 和实机硬件验证记录仍按当时范围解读。

## 共享平板实现整合

设备树由 278 个文件减至 124 个。公共设置应用、翻译与 hwcontrol 服务放在 common/tablet；节点、特性开关、音效 UUID、热策略值和刷新率保留在 nabu 配置。旧 Power HAL 移除，使用官方 Xiaomi libperfmgr 服务和 nabu powerhint.json。

实际编译通过：XiaomiTabletSettings、custom.hardware.hwcontrol-service、android.hardware.power-service.xiaomi-libperfmgr、libqti-perfd-client、selinux_policy、common 启动脚本、框架兼容矩阵，以及 bootimage/dtboimage/vendorbootimage。

APK 资源检查确认 6 个 nabu 特性均启用，刷新率配置为 default=120 / standard=60 / extreme=120，热策略节点和音效 UUID 来自 nabu。未提供配置的 common 默认库关闭所有设备特性。安装的 6 个 common 启动脚本与源文件一致，均可执行；安装的 powerhint.json 与 nabu 文件一致。

静态检查通过：437 项设备 blobs、788 项 common blobs、XML 和 1498 个复制目的地。common 的手机分支保留原默认路径，tablet namespace/策略仅由 TARGET_IS_TABLET 选择。

本次更换了 Power HAL，CPU/GPU hint、热策略、功耗及正常系统的笔/键盘/UI 行为仍需实机验证。日志：/tmp/nabu-shared-check/。

## product 镜像空间修复

完整构建在 target-files 的 product.img 生成阶段失败：460 MiB 文件树加约 29 MiB 预留空间，但继承的 `product_extfs_inode_count=-1` 让 mke2fs 创建了 125312 个 inode，inode 表与文件系统元数据耗尽了预留空间。nabu 侧清空 product/system/system_ext 的显式 inode 数，让 build_image 按实际文件树计算；common 保持原配置。

构建变量解析确认三个 inode 设置为空、预留空间仍为 30720000 字节。使用失败构建的 PRODUCT 文件树、filesystem_config 和 SELinux contexts，单独生成 product.img 成功（包括 AVB hashtree/footer）；最终文件系统 640 个 inode，剩余 7180 个 4 KiB block。验证产物位于 `/tmp/nabu-product-inodes-check/`，尚未重新完成完整 ROM/OTA 打包。
