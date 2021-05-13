D SDL2 Demo project based on SDL2's android_project.

This guide doesn't cover every aspect in detail, but rather provides overview of the process with some details.

In this demo you'll see how to organize project and build Android app using standard D tools and gradle.
There is not much going on graphics-wise, it is more like a project skeleton for you to start.

SDL stands for Simple DirectMedia Layer - "a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D."

It is primarily used in game development, but it can be used to build graphics apps with it.

---

PREREQUISITES:
 - `ldc2` D compiler
 - `dub` build system (usually shipped with D compiler)
 - `gradle` build system (this project already provides gradle wrapper)
 - Java Development Kit (**NOTE: JDK 16 IS BORKEN, DO NOT USE**)
 - Android SDK & NDK (if you have NDK installed with Android Studio it is likely located at `$SDK_PATH/ndk`)
 - `Ninja` build system
 - `CMake` (meta) build system

Tested versions:
- ldc2 v1.26
- gradle 7.0
- OpenJDK 15
- NDK 21.3
- Android SDK 30
- CMake 3.19
---

Note that for the rest of the tutorial we stick to Android Native API v21, and for Vulkan minimal level Android API 25

### Conventions:   
All shell commands in this document are for Windows, all paths are in UNIX format.

Environment variables conventions in this document:  
- `$ANDROID_SDK` is the root of your Android SDK setup
- `$NDK_HOME` is Android NDK setup location
- `$LDC_PATH` LDC2 compiler install location
- `$PROJECT` root directory of this repo

---

Overview:

0) Confgiure LDC and NDK
   - Configure LDC
   - Build D runtime for Android
   - Set up BFD linker for NDK toolchain

1) Build SDL2 

2) Build shared libraries

3) Build Android project 

4) Deploy on mobile

---

## 0) Configure LDC and NDK

Using this setup and `--link-defaultlib-debug=true` ldc2 flag will let you to debug native code using Android Studio, 
but no sources will be shown for Phobos and D runtime, it might be possible to improve this 
by pointing out to actual build location instead, but I haven't tried it.

For more info refer to D wiki about cross compilation
https://wiki.dlang.org/Build_D_for_Android#Cross-compilation_setup

NOTE: it uses clang and not clang++ binary for gcc, if you choose clang++ it will fail to start because clang++ links libc++_shared.so STL by default and it requires extra build steps.

NOTE: on Windows using .cmd extension is required for gcc entry

Edit your `$LDC_PATH/etc/ldc2.conf` and add the following sections with paths to your local NDK toolchain setup
For targeting ARM64 64-bit CPU's
```sh
"aarch64-.*-linux-android":
{
    switches = [
        "-defaultlib=phobos2-ldc,druntime-ldc",
        "-link-defaultlib-shared=false",
        "-gcc=$NDK_PATH/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd",
    ];
    lib-dirs = [
        "%%ldcbinarypath%%/../lib-android_aarch64",
    ];
    rpath = "";
};
```

For targeting ARMv7 32-bit older CPU's
```sh
"armv7a-.*-linux-android":
{
    switches = [
        "-defaultlib=phobos2-ldc,druntime-ldc",
        "-link-defaultlib-shared=false",
        "-gcc=$NDK_PATH/toolchains/llvm/prebuilt/windows-x86_64/bin/armv7a-linux-androideabi21-clang.cmd",
    ];
    lib-dirs = [
        "%%ldcbinarypath%%/../lib-android_armv7a",
    ];
    rpath = "";
};
```

### Build D runtime for LDC

Updated version of 
https://wiki.dlang.org/Building_LDC_runtime_libraries

For ARM64
```sh
ldc-build-runtime --ninja \
   --dFlags="-mtriple=arm64--linux-androideabi" \
   --targetSystem="Android;Linux;UNIX" \
   CMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
   ANDROID_ABI=arm64-v8a  \
   ANDROID_NATIVE_API_LEVEL=21

cp lib/* $LDC_PATH/lib-android_aarch64
```
or for ARMv7
```sh
ldc-build-runtime --ninja \
   --dFlags="-mtriple=armv7a--linux-androideabi" \
   --targetSystem="Android;Linux;UNIX" \
   CMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
   ANDROID_ABI=armeabi-v7a \
   ANDROID_NATIVE_API_LEVEL=21

cp lib/* $LDC_PATH/lib-android_armv7a
```

After you build it, copy the libs to `$LDC_PATH/lib-android_aarch64` (or `$LDC_PATH/lib-android_armv7a` respectively) as was set in ldc2.conf in previous step.


### **Set up BFD linker for NDK toolchain**

LDC's D runtime on Android requires .tbss and .tdata sections to be in specific order which is only the case when linking with bfd linker, otherwise it'll throw exception on rt_init()  
Luckily NDK still has bfd so all we need is to copy it next to NDK's clang

(Change 21.3.6528147 to your NDK version)
```sh
cp $NDK_PATH/21.3.6528147/toolchains/aarch64-linux-android-4.9/prebuilt/windows-x86_64/bin/aarch64-linux-android-ld.bfd.exe $NDK_PATH/toolchains/llvm/prebuilt/windows-x86_64/bin/ld.bfd.exe
```

## 1) Build SDL2

Clone SDL2 using git *(or just download & extract zip archive)* and build with cmake with NDK toolchain using Ninja generator.

For ANDROID_ABI list and available options refer to NDK cmake guide (we are interesting in `armeabi-v7a` and `arm64-v8a` ABI's)
https://developer.android.com/ndk/guides/cmake

Setting CMAKE_INSTALL_PREFIX isn't strictly necessary in our case.

```
git clone https://github.com/libsdl-org/SDL.git
```
ARMv7:
```sh
    cd SDL
    mkdir build-armv7a
    cd build-armv7a

    cmake .. -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=armeabi-v7a \
    -DANDROID_NATIVE_API_LEVEL=24 \
    -DCMAKE_INSTALL_PREFIX="./install" \
    -G Ninja

    cmake --build . --config Release

    cp libSDL2.so $PROJECT/app/libs/armeabi-v7a/libSDL2.so
    cp libhidapi.so $PROJECT/app/libs/armeabi-v7a/libhidapi.so
```

ARM64:
```sh
    cd SDL
    mkdir build-arm64
    cd build-arm64

    cmake .. -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=aarch64-v7a \
    -DANDROID_NATIVE_API_LEVEL=24 \
    -DCMAKE_INSTALL_PREFIX="./install" \
    -G Ninja

    cmake --build . --config Release

    cp libSDL2.so $PROJECT/app/libs/arm64-v8a/libSDL2.so
    cp libhidapi.so $PROJECT/app/libs/arm64-v8a/libhidapi.so
```

After that copy `libSDL2.so` and `libhidapi.so` to `app/libs` folder with respect to the platform architecture.  
Gradle will bundle that folder automatically later on during APK build.

## 2) Build shared libraries

At this moment we are ready to build our main program. If everything was set up correctly it is as simple as running `dub build --arch=$TARGET_ARCH$` (or shorthand -a for arch)

ARM64
```
  dub build -a aarch64-none-linux-android
```
ARMv7
```
dub build -a armv7a-none-linux-android
```

Since Android apps can have multiple platforms you can do both, but for the rest of the tutorial we are focus on ARM64.

At this point it should be possible to develop your app on your PC and periodcally test it on mobile, this opens up possibility to greatly reduce iteration time and increase both development speed and convenience.

---
### Here goes mobile part 
---


## 3) Build Android project

We now have everything we need to build Android project.  
Run gradle and build Debug configuration, this will produce APK that we will install on device in next step.

(note we are using `buildDebug` configuration and not `build` which defaults to Release)
```ps
  $env:ANDROID_HOME=$ANDROID_SDK
  $env:ANDROID_NDK_HOME=$ANDROID_NDK
  ./gradlew buildDebug
```

Alternatively you can open Android Studio and choose Open Project, then navigate to this project and open `$PROJECT/build.gradle`, after it loads you can choose `app` target in toolbar and hit green hammer icon to build the project.

## 4) Deploy on mobile

To install debug build on your phone
```sh
./gradlew installDebug
```

After that you should be able to run this demo on your device

If you use Android Studio build & install is performed when you click Run or Debug button.

---

When your app is ready to be shipped it needs to be packed (like in previous step) and signed. 

To create and sign an APK gradle provides `assembleRelease` task.  
This however is outside of the scope of this guide.

There is also `bundleRelease` task to create special archived version containing all the resources but delay actual bundling and signing to be later performed by Google Play store.

(app is the app folder with build.gradle project)
```sh
  ./gradlew :app:bundleDebug
```


