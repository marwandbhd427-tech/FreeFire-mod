ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeFireVIP

FreeFireVIP_FILES = main_fixed.mm
FreeFireVIP_CFLAGS = -fobjc-arc -std=c++17 -Wno-deprecated-declarations
FreeFireVIP_LDFLAGS = -framework Metal -framework MetalKit -framework Foundation -framework UIKit
FreeFireVIP_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/library.mk
