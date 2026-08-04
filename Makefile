ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeFireVIP

IMGUI_DIR = IMGUI
DOBBY_DIR = 5Toubun

# ✅ نكتشف ملفات Dobby تلقائياً (كل .cpp و .cc و .mm و .c)
DOBBY_FILES := $(shell find $(DOBBY_DIR)/source -type f \( -name "*.cpp" -o -name "*.cc" -o -name "*.mm" -o -name "*.c" \) 2>/dev/null)

FreeFireVIP_FILES = main_fixed.mm \
    $(IMGUI_DIR)/imgui.cpp \
    $(IMGUI_DIR)/imgui_draw.cpp \
    $(IMGUI_DIR)/imgui_widgets.cpp \
    $(IMGUI_DIR)/imgui_tables.cpp \
    $(IMGUI_DIR)/imgui_impl_metal.mm \
    $(DOBBY_FILES)

FreeFireVIP_CFLAGS = -fobjc-arc -std=c++17 -Wno-deprecated-declarations \
    -I$(IMGUI_DIR) \
    -I$(DOBBY_DIR)/include \
    -I$(DOBBY_DIR)/source \
    -DDOBBY_DEBUG=OFF

FreeFireVIP_LDFLAGS = -framework Metal -framework MetalKit -framework Foundation -framework UIKit
FreeFireVIP_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/library.mk
