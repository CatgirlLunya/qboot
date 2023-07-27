# https://stackoverflow.com/a/23324703
export ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export BUILD_DIR := $(ROOT_DIR)/build
export STAGE1_DIR := $(ROOT_DIR)/stage1
export STAGE2_DIR := $(ROOT_DIR)/stage2

.PHONY: run all debug clean clangd test

include toolchain.mk

all: $(BUILD_DIR)/disk.dd $(BUILD_DIR)/stage1.bin $(BUILD_DIR)/stage2.bin
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/disk.dd conv=notrunc
# Seeks to the start of the partition where stage2 is
	dd if=$(BUILD_DIR)/stage2.bin of=$(BUILD_DIR)/disk.dd seek=1048576 conv=notrunc bs=1

run: all
	scripts/run.sh $(BUILD_DIR)

debug: all
	scripts/bochs.sh $(ROOT_DIR)

clangd: clean
	bear -- make all

clean:
	rm -r $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)

include stage1/Makefile
include stage2/Makefile

# Creates the disk image using some hacky fdisk stuff b/c I don't want to figure out anything else rn
$(BUILD_DIR)/disk.dd:
	scripts/prep_disk.sh $(BUILD_DIR)
