DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64

# Share the SDK and deployment targets with the PreferenceBundle.
include AxsNotchHomeFixBuild.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxsNotchHomeFix
AxsNotchHomeFix_FILES = $(wildcard Hooks/*.xm Sources/*.m)
AxsNotchHomeFix_CFLAGS = -fobjc-arc -I./Headers -I./Sources
AxsNotchHomeFix_FRAMEWORKS = UIKit Foundation CoreFoundation
AxsNotchHomeFix_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk


