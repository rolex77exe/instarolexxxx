ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = TikTok
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Rolex7exeTikTok

Rolex7exeTikTok_FILES = Tweak.xm
Rolex7exeTikTok_CFLAGS = -fobjc-arc
Rolex7exeTikTok_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
