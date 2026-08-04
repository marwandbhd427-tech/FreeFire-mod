ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeFireVIP

IMGUI_DIR = IMGUI
DOBBY_DIR = 5Toubun

FreeFireVIP_FILES = main_fixed.mm \
    $(IMGUI_DIR)/imgui.cpp \
    $(IMGUI_DIR)/imgui_draw.cpp \
    $(IMGUI_DIR)/imgui_widgets.cpp \
    $(IMGUI_DIR)/imgui_tables.cpp \
    $(IMGUI_DIR)/imgui_impl_metal.mm

FreeFireVIP_CFLAGS = -fobjc-arc -std=c++17 -Wno-deprecated-declarations \
    -I$(IMGUI_DIR) \
    -I$(DOBBY_DIR)/include

FreeFireVIP_LDFLAGS = -framework Metal -framework MetalKit -framework Foundation -framework UIKit \
    -L$(DOBBY_DIR)/build -ldobby

FreeFireVIP_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/library.mk
