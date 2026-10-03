// Copyright (C) 2026 The LineageOS Project
// SPDX-License-Identifier: Apache-2.0
#include <android-base/file.h>
#include <android-base/logging.h>
#include "TouchFeatureState.h"

void setTouchFeatureState(int feature, int state) {
    const char* node;
    switch (feature) {
        case TOUCH_FEATURE_TAP2WAKE: node = "/sys/touchpanel/double_tap"; break;
        case TOUCH_FEATURE_STYLUS: node = "/sys/touchpanel/pen"; break;
        default: return;
    }
    if (!android::base::WriteStringToFile(state > 0 ? "1" : "0", node)) {
        PLOG(ERROR) << "Unable to write " << node;
    }
}
