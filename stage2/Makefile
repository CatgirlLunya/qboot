

SUBDIRECTORIES := $(dir $(wildcard stage2/*/))
BUILD_SUBDIRECTORIES := $(addprefix $(BUILD_DIR)/, $(SUBDIRECTORIES))

C_FILES := $(wildcard stage2/*.c)
C_FILES += $(wildcard stage2/*/*.c)
ASM_FILES := $(wildcard stage2/*.asm)
ASM_FILES += $(wildcard stage2/*/*.asm)
STAGE2_OBJ := $(addprefix $(BUILD_DIR)/stage2/, $(ASM_FILES:stage2/%.asm=%.o) $(C_FILES:stage2/%.c=%.o))

$(BUILD_DIR)/stage2.bin: $(STAGE2_OBJ)
	$(LD) $^ $(LD_FLAGS) -o $(BUILD_DIR)/stage2/stage2.elf
	objcopy -O binary $(BUILD_DIR)/stage2/stage2.elf $@ 

$(BUILD_DIR)/stage2/%.o: stage2/%.c build_dirs 
	$(CC) $(C_FLAGS) -c $< -o $@ -I stage2

$(BUILD_DIR)/stage2/%.o: stage2/%.asm build_dirs
	nasm $< -Wall -Werror -felf32 -o $@

.PHONY: build_dirs

build_dirs:
	mkdir -p $(BUILD_SUBDIRECTORIES)
