ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FreeFireVIP

IMGUI_DIR = IMGUI
DOBBY_DIR = 5Toubun

# ✅ نبني ملفات Dobby المصدرية مباشرة مع المشروع
FreeFireVIP_FILES = main_fixed.mm \
    $(IMGUI_DIR)/imgui.cpp \
    $(IMGUI_DIR)/imgui_draw.cpp \
    $(IMGUI_DIR)/imgui_widgets.cpp \
    $(IMGUI_DIR)/imgui_tables.cpp \
    $(IMGUI_DIR)/imgui_impl_metal.mm \
    $(DOBBY_DIR)/source/Interceptor.cpp \
    $(DOBBY_DIR)/source/InterceptorArm64.cpp \
    $(DOBBY_DIR)/source/ClosureTrampoline.cpp \
    $(DOBBY_DIR)/source/InstructionRelocation/InstructionRelocationArm64.cpp \
    $(DOBBY_DIR)/source/MemoryAllocator/CodeBuffer.cpp \
    $(DOBBY_DIR)/source/MemoryAllocator/AssemblyCodeBuilder.cpp \
    $(DOBBY_DIR)/source/TrampolineBridge/TrampolineBridge.cpp

FreeFireVIP_CFLAGS = -fobjc-arc -std=c++17 -Wno-deprecated-declarations \
    -I$(IMGUI_DIR) \
    -I$(DOBBY_DIR)/include \
    -I$(DOBBY_DIR)/source \
    -DDOBBY_DEBUG=OFF

FreeFireVIP_LDFLAGS = -framework Metal -framework MetalKit -framework Foundation -framework UIKit

FreeFireVIP_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/library.mk
