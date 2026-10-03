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
| common 补丁 git apply --check | 通过 | upstream-lock.json 对应的干净官方 common checkout |

内核 `.config` 已确认以下选项为 y：MACH_XIAOMI_NABU、TOUCHSCREEN_NT36523_HOSTDL_SPI、TOUCHSCREEN_COMMON、SND_SOC_CS35L41_V2、MSM_CSPL_V2、BATT_VERIFY_BY_DS28E16_NABU、IDT_P9418、BQ2597X_CHARGE_PUMP、CHARGER_LN8000、ANDROID_BINDERFS。

复制目的地检查仅保留了 AOSP / Lineage 基础产品中已有的两个声音文件重复目的地（Pyxis.ogg、Effect_Tick.ogg）；Android 按首个条目选择。没有 nabu/common 的 blob 交叉重复或设备文件复制冲突。

完整 ROM、内核镜像编译、刷机与实机测试尚未执行。上述结果不证明可以开机，也不覆盖相机、功耗、笔/键盘、充电或 OTA 的实际功能。

完整工具日志保存在本次会话的临时参考目录 `/tmp/nabu-los20-reference/`：breakfast.log、graph.log、brunch-dry-run.log、selinux.log、kernel-config.log；精确源提交见 upstream-lock.json。
