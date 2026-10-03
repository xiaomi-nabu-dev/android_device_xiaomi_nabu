# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

TARGET_IS_TABLET := true
TARGET_COMMON_VENDOR_PRODUCT := device/xiaomi/nabu/common-vendor.mk
TARGET_WIFI_OVERLAY := NabuWifiOverlay
TARGET_IS_VAB := true
$(call inherit-product, device/xiaomi/sm8150-common/msmnile.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/window_extensions.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
PRODUCT_SHIPPING_API_LEVEL := 30
PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xhdpi
PRODUCT_AAPT_PREBUILT_DPI := xxxhdpi xxhdpi xhdpi hdpi
TARGET_SCREEN_HEIGHT := 2560
TARGET_SCREEN_WIDTH := 1600
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# The stock nabu audio HAL includes the four-speaker amplifier handling.
PRODUCT_PACKAGES += android.hardware.boot@1.1-impl-qti android.hardware.boot@1.1-impl-qti.recovery android.hardware.boot@1.1-service
PRODUCT_PACKAGES += update_engine update_engine_sideload update_verifier otapreopt_script checkpoint_gc
AB_OTA_POSTINSTALL_CONFIG += RUN_POSTINSTALL_system=true POSTINSTALL_PATH_system=system/bin/otapreopt_script FILESYSTEM_TYPE_system=ext4 POSTINSTALL_OPTIONAL_system=true
AB_OTA_POSTINSTALL_CONFIG += RUN_POSTINSTALL_vendor=true POSTINSTALL_PATH_vendor=bin/checkpoint_gc FILESYSTEM_TYPE_vendor=ext4 POSTINSTALL_OPTIONAL_vendor=true
PRODUCT_PACKAGES_DEBUG += bootctl
PRODUCT_PACKAGES += libpiex_shim android.hardware.thermal@2.0-service.qti
PRODUCT_PACKAGES += android.hardware.power-service-nabu
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,$(LOCAL_PATH)/audio/,$(TARGET_COPY_OUT_VENDOR)/etc)

# Unchanged SoC audio configuration comes from common.
PRODUCT_COPY_FILES += \
    device/xiaomi/sm8150-common/audio/bluetooth_hearing_aid_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_hearing_aid_audio_policy_configuration.xml \
    device/xiaomi/sm8150-common/audio/audio_tuning_mixer.txt:$(TARGET_COPY_OUT_VENDOR)/etc/audio_tuning_mixer.txt \
    device/xiaomi/sm8150-common/audio/graphite_ipc_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/graphite_ipc_platform_info.xml \
    device/xiaomi/sm8150-common/audio/audio_tuning_mixer_tavil.txt:$(TARGET_COPY_OUT_VENDOR)/etc/audio_tuning_mixer_tavil.txt
PRODUCT_COPY_FILES += $(LOCAL_PATH)/configs/public.libraries.txt:$(TARGET_COPY_OUT_VENDOR)/etc/public.libraries.txt
PRODUCT_COPY_FILES += $(LOCAL_PATH)/configs/component-overrides.xml:$(TARGET_COPY_OUT_VENDOR)/etc/sysconfig/component-overrides.xml
PRODUCT_COPY_FILES += frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml
PRODUCT_COPY_FILES += frameworks/native/data/etc/android.software.freeform_window_management.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.freeform_window_management.xml
PRODUCT_COPY_FILES += frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml
PRODUCT_COPY_FILES += frameworks/native/data/etc/android.software.managed_users.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.managed_users.xml

PRODUCT_COPY_FILES += $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom
PRODUCT_COPY_FILES += $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom
PRODUCT_PACKAGES += nabu_init.class_main.sh nabu_init.qcom.class_core.sh nabu_init.qcom.early_boot.sh nabu_init.qcom.post_boot.sh nabu_init.qcom.sh nabu_init.qcom.usb.sh nabu_init.qti.chg_policy.sh nabu_init.qti.dcvs.sh
PRODUCT_PACKAGES += nabu_init.qcom.power.rc nabu_init.qcom.rc nabu_init.qcom.usb.rc nabu_init.recovery.qcom.rc nabu_init.target.rc nabu_init.xiaomi.rc nabu_ueventd.qcom.rc nabu_init.nabu.perf.rc
PRODUCT_COPY_FILES += device/xiaomi/sm8150-common/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf
PRODUCT_COPY_FILES += $(LOCAL_PATH)/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf
PRODUCT_COPY_FILES += $(LOCAL_PATH)/wifi/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/WCNSS_qcom_cfg.ini
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-lineage
PRODUCT_PACKAGES += SystemUIOverlayNabu SettingsProviderOverlayNabu SettingsOverlayNabu FrameworkResOverlayNabu
$(call inherit-product, vendor/xiaomi/nabu/nabu-vendor.mk)

# Standard policy includes referenced by the nabu policy.
PRODUCT_COPY_FILES += frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml
PRODUCT_COPY_FILES += frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml
PRODUCT_COPY_FILES += frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml
PRODUCT_COPY_FILES += frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml

PRODUCT_PACKAGES += XiaomiPad5Settings custom.hardware.hwcontrol-service

# Use the upstream Xiaomi camera compatibility stubs.
PRODUCT_PACKAGES += libMegviiFacepp-0.5.2 libmegface

# Native USB debugging before framework startup. The normal adbd service is
# released when APEX activation completes; recovery has its own post-fs hook.
PRODUCT_PACKAGES_DEBUG += nabu-debug-init
ifneq ($(filter userdebug eng,$(TARGET_BUILD_VARIANT)),)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.adb.secure.recovery=0 \
    persist.sys.usb.config=adb
endif
