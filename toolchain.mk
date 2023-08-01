CROSS_GCC := $(shell which i686-elf-gcc)
export CC := $(CROSS_GCC)
export LD := $(CC)
export CXX := $(subst gcc,g++,$(CROSS_GCC))
export ASM := nasm
export TESTING_CC := gcc
export TESTING_CXX := g++
export TESTING_LD := gcc

# c11, freestanding, no PIE, no floats, all possible warnings, optimized for size, and min pagesize needed to access first 4 kb of memory
export C_FLAGS := \
	-Os \
	-std=c11 \
	-ffreestanding \
	-fomit-frame-pointer \
	-fno-PIE \
	-fno-PIC \
	-fno-lto \
	-march=i686 \
	-mno-80387 \
	-Wpedantic \
	-Wall \
	-Wextra \
	-Werror \
	-Wconversion \
	--param=min-pagesize=0
	

export LD_FLAGS := \
	-nostdlib \
	-l:libgcc.a \
	-z max-page-size=0x1000 \
	-static \
	-T $(STAGE2_DIR)/linker.ld

export TESTING_C_FLAGS := \
	-Os \
	-std=c11 \
	-ffreestanding \
	-Wall \
	-m32 \
	-no-pie \
	-I stage2 \
	-g \
	-pthread # Needed b/c gtest uses it by default

export TESTING_CXX_FLAGS := \
	-Os \
	-std=c++17 \
	-Wall \
	-m32 \
	-no-pie \
	-I stage2 \
	-g \
	-pthread

export TESTING_LD_FLAGS := \
	-pthread \
	-m32 \
	-lgtest \
	-lgtest_main \
	-lstdc++ \
	-lm 
	