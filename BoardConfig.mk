# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

include device/xiaomi/sm8150-common/BoardConfigCommon.mk
DEVICE_PATH := device/xiaomi/nabu
TARGET_OTA_ASSERT_DEVICE := nabu
TARGET_BOOTLOADER_BOARD_NAME := nabu
BOARD_HAVE_QCOM_FM := false
ENABLE_VENDOR_RIL_SERVICE := false
ODM_MANIFEST_SKUS :=
ODM_MANIFEST_NFC_FILES :=

# Nabu ships virtual A/B with recovery in vendor_boot, not a recovery partition.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := boot dtbo odm product system system_ext vbmeta vbmeta_system vendor_boot vendor
BOARD_BOOT_HEADER_VERSION := 3
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_KERNEL_CMDLINE += kpti=off
TARGET_KERNEL_CONFIG += vendor/xiaomi/nabu.config
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_CACHEIMAGE_PARTITION_SIZE :=
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE :=
BOARD_RECOVERYIMAGE_PARTITION_SIZE :=
BOARD_USERDATAIMAGE_PARTITION_SIZE :=
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RELEASETOOLS_EXTENSIONS :=
# Do not reserve several GiB of phone system image slack in the A/B super group.
$(foreach p,$(call to-upper,$(ALL_PARTITIONS)),$(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 30720000))

TARGET_SCREEN_DENSITY := 350
TARGET_USES_QTI_CAMERA_DEVICE := true
TARGET_INIT_VENDOR_LIB := //$(DEVICE_PATH):init_nabu
TARGET_RECOVERY_DEVICE_MODULES := init_nabu
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs
TARGET_TAP_TO_WAKE_NODE := "/sys/touchpanel/double_tap"
TARGET_USES_NON_LEGACY_POWERHAL := true
TARGET_USES_INTERACTION_BOOST := true

TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop
VENDOR_SECURITY_PATCH := 2023-01-01
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
# Nabu has no phone-only HALs; use the tablet's complete manifest.
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := $(DEVICE_PATH)/framework_compatibility_matrix.xml vendor/lineage/config/device_framework_matrix.xml
TARGET_WLAN_MAC_PATH := /mnt/vendor/persist/wlan/wlan_mac.bin
WIFI_HIDL_FEATURE_AWARE := true
WIFI_FEATURE_HOSTAPD_11AX := true
include vendor/xiaomi/nabu/BoardConfigVendor.mk
