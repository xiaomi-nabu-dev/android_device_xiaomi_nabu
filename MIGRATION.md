# nabu：LineageOS 20 / 官方 sm8150-common 拆分

实现目录：`/home/dengxh/android2/lineage`。原目录 `/home/dengxh/android/lineage/device/xiaomi/nabu` 未修改。

## 基线与选择

| 目录 | 上游 / 分支 | 本地修改 |
| --- | --- | --- |
| device/xiaomi/sm8150-common | LineageOS / lineage-20 | 平板继承开关、可选 vendor 产品入口与 Wi-Fi overlay、平板属性 |
| kernel/xiaomi/sm8150 | LineageOS / lineage-22.2 | 无源码修改，工作分支名 nabu-los20 |
| vendor/xiaomi/sm8150-common | TheMuppets / lineage-20 | 无修改 |
| hardware/xiaomi | LineageOS / lineage-20 | 无修改 |
| device/xiaomi/nabu | dev-harsh1998 / lineage-20 | 拆分后的 nabu 设备树 |
| vendor/xiaomi/nabu | dev-harsh1998 / lineage-20 | 仅保留 nabu 专有文件并重新生成构建文件 |

精确上游基线提交见 `upstream-lock.json`。现有目录是独立 Git checkout，已补齐所有远程分支和标签的历史。nabu 设备树、nabu vendor 以及 common 兼容改动分别提交在本地 `nabu-los20` 分支，尚未推送；使用各目录的 `git log` 和 `git show` 审阅。

官方内核没有 lineage-20 分支，lineage-19.1 又缺少 nabu 驱动和配置。使用已有 nabu 支持的 lineage-22.2 内核，Android 用户空间仍是 13 / LOS 20。内核配置沿用 sm8150-perf_defconfig + sm8150-common.config + nabu.config；配置生成已经检查，整颗内核编译与启动仍需后续验证。

common blobs 使用实际存在的 lineage-20 分支，而不是题目给出的 lineage-21。22.2 的第三方拆分树仅用于核对拆分思路和音频重命名；没有整体回退其 Android 15 配置。

## 拆分边界

common 继续提供 Qualcomm 音频接口、图形、蓝牙、相机 provider、传感器接口、Wi-Fi、共享 blobs 和通用 SELinux。common 的手机产品保持默认路径；nabu 设置 TARGET_IS_TABLET，并显式选用自己的 vendor 包装文件和 Wi-Fi overlay。

nabu 保留：

- 虚拟 A/B、boot header v3、vendor_boot 中的 recovery、nabu fstab 和 OTA 分区清单。
- 2560×1600 平板配置、350 dpi、nabu RRO、设备身份和初始化。
- 四扬声器音频 HAL、功放固件和校准，nabu 相机、传感器、热管理、性能服务配置。
- 平板设置、键盘和笔控制、nabu Power HAL 与设备 SELinux 增量。

不导出 common 的手机 rootdir Soong namespace，避免同名安装目标覆盖 nabu 启动文件。common-vendor.mk 包装上游 vendor 产品文件，过滤手机 RIL/IMS、GNSS、FM、支付和升降摄像头文件；没有修改上游 common vendor 仓库。

nabu 专有列表保留 439 项，按最终安装路径去重，与 common 不重叠。

相机使用 hardware/xiaomi 自带的 libMegviiFacepp-0.5.2 / libmegface 兼容桩和 Lineage 的 libpiex_shim；避免旧 blob 副本与现有源码模块的安装冲突。实际相机功能仍需实机验证。LOS 20 当前 hardware/qcom-caf/common 没有 source libqti-perfd-client，nabu 保留原来的两个架构的专有客户端。

音频 HAL 重命名为 audio.primary.nabu.so，并设置 ro.hardware.audio=nabu；它动态加载的 offload 库改名为 liba2dpoffload_nabu.so，避免覆盖共享实现。extract-files.sh 内的修复函数保证后续提取能重现此变更。

官方内核控制接口与旧树不同，已调整：

- 双击唤醒：`/sys/touchpanel/double_tap`。
- 笔输入：`/sys/touchpanel/pen`。
- 键盘启用：`/sys/devices/platform/soc/soc:xiaomi_keyboard/xiaomi_keyboard_enabled`，读写数值 0/1。

控制服务安装到 system_ext，与设备 SELinux 所在分区一致；init 服务路径、节点所有权和标签同步调整。OTA 使用 payload 中的分区清单，不再使用旧的非 A/B Edify 写入未带槽后缀的分区。

## 编译与维护

```bash
cd /home/dengxh/android2/lineage
source build/envsetup.sh
breakfast nabu
brunch nabu
```

需要自行限制并行数时，breakfast 之后运行 `mka bacon -j8`。不要把 `-j8` 当作 breakfast/brunch 的设备 variant 参数。

仅检查完整构建图（不编译 ROM）：

```bash
m nothing
NINJA_ARGS=-n brunch nabu
```

静态检查：

```bash
python3 device/xiaomi/nabu/tools/validate-tree.py
get_build_var PRODUCT_COPY_FILES > /tmp/nabu-copy-files.txt
python3 device/xiaomi/nabu/tools/validate-tree.py --copy-files /tmp/nabu-copy-files.txt
```

重新提取 nabu blobs 时，只操作 nabu vendor：

```bash
bash device/xiaomi/nabu/extract-files.sh /path/to/nabu/dump
bash device/xiaomi/nabu/setup-makefiles.sh
```

共享 blobs 继续使用锁定的 TheMuppets common checkout；不要从单一 nabu dump 盲目覆盖 common 中来自其他固件的固定版本。

common 的补丁保存在 `patches/sm8150-common-lineage-20-tablet.patch`。在 upstream-lock.json 对应的干净 common checkout 中可以 `git apply --check` 后应用。更新 common 时应同步检查此补丁和 common-vendor.mk 的过滤目的地，再重新做构建图验证。

## 验证范围

最终执行记录见 `VALIDATION.md`。配置选择、构建图和静态检查不能证明设备可以开机；完整编译、刷机与实机功能验证尚未进行。特别需要验证 recovery/解密、OTA 槽切换、触控和笔、键盘、120 Hz、四扬声器、相机、传感器、Wi-Fi/蓝牙、充电与待机功耗。
