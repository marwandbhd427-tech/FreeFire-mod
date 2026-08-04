name: Build FreeFireVIP dylib

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - name: 📥 Checkout
      uses: actions/checkout@v4

    - name: 📦 Clone ImGui
      run: |
        git clone --depth 1 https://github.com/ocornut/imgui.git IMGUI
        cp IMGUI/backends/imgui_impl_metal.h IMGUI/
        cp IMGUI/backends/imgui_impl_metal.mm IMGUI/

    - name: 🔧 Install Theos
      run: |
        git clone --recursive https://github.com/theos/theos.git ~/theos
        echo "THEOS=${HOME}/theos" >> $GITHUB_ENV

    - name: 📦 Download iOS SDK
      run: |
        curl -LO https://github.com/theos/sdks/archive/refs/heads/master.zip
        unzip -q master.zip
        mkdir -p ~/theos/sdks
        mv sdks-master/*.sdk ~/theos/sdks/ 2>/dev/null || true
        rm -rf master.zip sdks-master

    - name: 🔨 Clone Dobby (بدون بناء macOS)
      run: |
        git clone --depth 1 https://github.com/jmpews/Dobby.git 5Toubun

    - name: 🏗️ Build dylib (مع Dobby كـ static)
      run: |
        export THEOS=~/theos
        export PATH=$THEOS/bin:$PATH
        # نضيف ملفات Dobby مباشرة للبناء بدل libdobby.dylib
        make

    - name: 📤 Upload dylib
      uses: actions/upload-artifact@v4
      with:
        name: FreeFireVIP-dylib
        path: .theos/obj/debug/*.dylib
