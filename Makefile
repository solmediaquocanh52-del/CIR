ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CircleSwitcher
CircleSwitcher_FILES = Tweak.x
CircleSwitcher_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
CircleSwitcher_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += CircleSwitcherPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
