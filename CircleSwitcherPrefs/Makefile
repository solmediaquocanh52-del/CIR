ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CircleSwitcherPrefs
CircleSwitcherPrefs_FILES = CSCircleSwitcherRootListController.mm CSCircleSwitcherLogoCell.mm CSCircleSwitcherPreviewHeader.mm CSCircleSwitcherEasterEgg.mm
CircleSwitcherPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
CircleSwitcherPrefs_FRAMEWORKS = UIKit QuartzCore CoreGraphics
CircleSwitcherPrefs_PRIVATE_FRAMEWORKS = Preferences
CircleSwitcherPrefs_INSTALL_PATH = /Library/PreferenceBundles

# Thêm đường dẫn trỏ trực tiếp đến PrivateFrameworks của SDK hiện tại
CircleSwitcherPrefs_LDFLAGS += -F$(THEOS)/include -F$(THEOS)/lib -F$(SYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_BASE_PATH)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_BASE_PATH)/Library/PreferenceLoader/Preferences/CircleSwitcher.plist$(ECHO_END)
