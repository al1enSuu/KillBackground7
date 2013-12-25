THEOS_DEVICE_IP = 192.168.1.109

TARGET = iphone:clang::7.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = KillBackground7
KillBackground7_FILES = Tweak.xm
KillBackground7_FRAMEWORKS = UIKit
KillBackground7_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = KillBackgroundPreferences
KillBackgroundPreferences_FILES = KillBackgroundPreferences.mm
KillBackgroundPreferences_INSTALL_PATH = /Library/PreferenceBundles
KillBackgroundPreferences_FRAMEWORKS = UIKit
KillBackgroundPreferences_PRIVATE_FRAMEWORKS = Preferences

include theos/makefiles/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/KillBackgroundPreferences.plist$(ECHO_END)

real-clean:
	rm -rf _
	rm -rf .obj
	rm -rf obj
	rm -rf .theos
	rm -rf *.deb

after-install::
	install.exec "killall -9 SpringBoard"
