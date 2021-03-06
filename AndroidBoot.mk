#Android makefile to build bootloader as a part of Android Build
ANDROID_TOP=$(shell pwd)
CLANG_BIN := $(ANDROID_TOP)/$(LLVM_PREBUILTS_PATH)/
ABL_USE_SDLLVM := false
#Extb841462,mayue.wt,18.11.13,modify,add sw_version inode,begin
include $(ANDROID_BUILD_TOP)/bootable/bootloader/edk2/devinfo/rules.mk
#Extb841462,mayue.wt,18.11.13,modify,add sw_version inode,end

ifneq ($(wildcard $(SDCLANG_PATH)),)
  ifeq ($(shell echo $(SDCLANG_PATH) | head -c 1),/)
    CLANG_BIN := $(SDCLANG_PATH)/
  else
    CLANG_BIN := $(ANDROID_TOP)/$(SDCLANG_PATH)/
  endif

  ABL_USE_SDLLVM := true
endif

# LD is not available for older Android versions
ifeq (1,$(filter 1,$(shell echo "$$(( $(PLATFORM_SDK_VERSION) > 27 ))" )))
LDOPT="-fuse-ld=$(ANDROID_TOP)/$(SOONG_LLVM_PREBUILTS_PATH)/ld.lld"
endif

# Use host tools from prebuilts. Partner should determine the correct host tools to use
PREBUILT_HOST_TOOLS := CC=$(ANDROID_TOP)/$(CLANG)\ \
		       CXX=$(ANDROID_TOP)/$(CLANG_CXX)\ \
		       LDPATH=$(LDOPT)\ \
		       AR=$(ANDROID_TOP)/$(HOST_AR)
PREBUILT_PYTHON_PATH=$(ANDROID_TOP)/prebuilts/python/linux-x86/2.7.5/bin/python2

DISABLE_PARALLEL_DOWNLOAD_FLASH := DISABLE_PARALLEL_DOWNLOAD_FLASH=0
ifeq ($(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_SUPPORTS_VERITY),true)
	VERIFIED_BOOT := VERIFIED_BOOT=1
else
	VERIFIED_BOOT := VERIFIED_BOOT=0
endif

ifeq ($(BOARD_BUILD_SYSTEM_ROOT_IMAGE),true)
        BUILD_SYSTEM_ROOT_IMAGE := BUILD_SYSTEM_ROOT_IMAGE=1
else
        BUILD_SYSTEM_ROOT_IMAGE := BUILD_SYSTEM_ROOT_IMAGE=0
endif

ifeq ($(BOARD_AVB_ENABLE),true)
	VERIFIED_BOOT_2 := VERIFIED_BOOT_2=1
else
	VERIFIED_BOOT_2 := VERIFIED_BOOT_2=0
endif

ifeq ($(BOARD_LEVB_ENABLE),true)
	VERIFIED_BOOT_LE := VERIFIED_BOOT_LE=1
else
	VERIFIED_BOOT_LE := VERIFIED_BOOT_LE=0
endif

ifeq ($(WT_COMPILE_FACTORY_VERSION),yes)
	WT_COMPILE_FACTORY_VERSION := yes
endif

ifeq ($(TARGET_BUILD_VARIANT),user)
	USER_BUILD_VARIANT := USER_BUILD_VARIANT=1
else
	USER_BUILD_VARIANT := USER_BUILD_VARIANT=0
endif

ifneq ($(TARGET_BOOTLOADER_BOARD_NAME),)
	BOARD_BOOTLOADER_PRODUCT_NAME := $(TARGET_BOOTLOADER_BOARD_NAME)
else
	BOARD_BOOTLOADER_PRODUCT_NAME := QC_Reference_Phone
endif

ifeq ($(BOARD_ABL_SAFESTACK_DISABLE),true)
	ABL_SAFESTACK := false
else
	ABL_SAFESTACK := true
endif

SAFESTACK_SUPPORTED_CLANG_VERSION = 6.0

# For most platform, abl needed always be built
# in aarch64 arthitecture to run.
# Specify BOOTLOADER_ARCH if needed to built with
# other ARCHs.
ifeq ($(BOOTLOADER_ARCH),)
	BOOTLOADER_ARCH := AARCH64
endif
TARGET_ARCHITECTURE := $(BOOTLOADER_ARCH)

ifeq ($(TARGET_ARCHITECTURE),arm)
	CLANG35_PREFIX := $(ANDROID_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-$(TARGET_GCC_VERSION)/bin/arm-linux-androideabi-
	CLANG35_GCC_TOOLCHAIN := $(ANDROID_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-$(TARGET_GCC_VERSION)
else
	CLANG35_PREFIX := $(ANDROID_TOP)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-$(TARGET_GCC_VERSION)/bin/aarch64-linux-android-
	CLANG35_GCC_TOOLCHAIN := $(ANDROID_TOP)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-$(TARGET_GCC_VERSION)
endif


# ABL ELF output
TARGET_ABL := $(PRODUCT_OUT)/abl.elf
TARGET_EMMC_BOOTLOADER := $(TARGET_ABL)
ABL_OUT := $(TARGET_OUT_INTERMEDIATES)/ABL_OBJ

abl_clean:
	$(hide) rm -f $(TARGET_ABL)

$(ABL_OUT):
	mkdir -p $(ABL_OUT)

# Top level target
$(TARGET_ABL): abl_clean | $(ABL_OUT) $(INSTALLED_KEYSTOREIMAGE_TARGET)
	$(MAKE) -C bootable/bootloader/edk2 \
		BOOTLOADER_OUT=../../../$(ABL_OUT) \
		all \
		PREBUILT_HOST_TOOLS=$(PREBUILT_HOST_TOOLS) \
		PREBUILT_PYTHON_PATH=$(PREBUILT_PYTHON_PATH) \
		$(BUILD_SYSTEM_ROOT_IMAGE) \
		$(VERIFIED_BOOT) \
		$(VERIFIED_BOOT_2) \
		$(VERIFIED_BOOT_LE) \
		$(USER_BUILD_VARIANT) \
		$(DISABLE_PARALLEL_DOWNLOAD_FLASH) \
		CLANG_BIN=$(CLANG_BIN) \
		CLANG_PREFIX=$(CLANG35_PREFIX)\
		ABL_USE_SDLLVM=$(ABL_USE_SDLLVM) \
		ABL_SAFESTACK=$(ABL_SAFESTACK) \
		SAFESTACK_SUPPORTED_CLANG_VERSION=$(SAFESTACK_SUPPORTED_CLANG_VERSION) \
		CLANG_GCC_TOOLCHAIN=$(CLANG35_GCC_TOOLCHAIN)\
		TARGET_ARCHITECTURE=$(TARGET_ARCHITECTURE) \
		BOARD_BOOTLOADER_PRODUCT_NAME=$(BOARD_BOOTLOADER_PRODUCT_NAME)

