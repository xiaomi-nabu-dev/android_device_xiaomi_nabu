# SPDX-License-Identifier: Apache-2.0
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.recovery.qcom.rc
LOCAL_MODULE_STEM := init.recovery.qcom.rc
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := etc/init.recovery.qcom.rc
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.class_main.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.class_main.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.class_main.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.class_main.sh
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.qcom.class_core.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.qcom.class_core.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.qcom.class_core.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.qcom.class_core.sh
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.qcom.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.qcom.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.qcom.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.qcom.sh
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.qcom.usb.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.qcom.usb.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.qcom.usb.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.qcom.usb.sh
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.qti.chg_policy.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.qti.chg_policy.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.qti.chg_policy.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.qti.chg_policy.sh
include $(BUILD_PREBUILT)

# Shared SoC script; preserve the nabu module's vendor install path.
include $(CLEAR_VARS)
LOCAL_MODULE := nabu_init.qti.dcvs.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_STEM := init.qti.dcvs.sh
LOCAL_SRC_FILES := ../../sm8150-common/rootdir/bin/init.qti.dcvs.sh
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := first
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_POST_INSTALL_CMD := chmod 0755 $(TARGET_OUT_VENDOR)/bin/init.qti.dcvs.sh
include $(BUILD_PREBUILT)
