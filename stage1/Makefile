$(BUILD_DIR)/stage1.bin: $(STAGE1_DIR)/boot.asm $(STAGE1_DIR)/gdt.asm
	nasm $(STAGE1_DIR)/boot.asm -I $(STAGE1_DIR) -f bin -o $(BUILD_DIR)/stage1.bin 