# Sets up a full list of test .cc files and all C/asm files to include from the bootloader
# Notably, this excludes the stage2 entry.asm and main.c, as entry.asm cannot be compiled properly
# and main.c defines main, which we don't want
CXX_FILES := $(wildcard test/*.cc)
OS_C_FILES := $(wildcard stage2/*/*.c)
OS_C_FILES += $(wildcard stage2/*.c)
OS_C_FILES := $(filter-out stage2/main.c,$(OS_C_FILES))
OS_ASM_FILES := $(wildcard stage2/*/*.asm)
OS_ASM_FILES += $(wildcard stage2/*.asm)
OS_ASM_FILES += stage1/gdt.asm
OS_ASM_FILES := $(filter-out stage2/entry.asm,$(OS_ASM_FILES))

OS_COMPILED_FILES = $(addprefix $(BUILD_DIR)/test/, $(subst /,-,$(OS_ASM_FILES:%.asm=%.o)) $(subst /,-,$(OS_C_FILES:%.c=%.o)))
TEST_FILES = $(addprefix $(BUILD_DIR)/,$(CXX_FILES:%.cc=%.o))

$(BUILD_DIR)/run_tests: $(OS_COMPILED_FILES) $(TEST_FILES)
	$(TESTING_LD) $^ $(TESTING_LD_FLAGS) -o $(BUILD_DIR)/run_tests

.SECONDEXPANSION:

# These both highlight badly, but they use second expansions to evaluate the
# %.c first, then substitute in and add the prefix
# This does not work without second expansions, as the subst is evaluated
# before the %.c
# Rule can take in f.e. test/stage1_boot.o and the dependency matches
# stage1/boot.asm or stage1/boot.c, whichever exists
$(BUILD_DIR)/test/%.o: $$(addprefix $(ROOT_DIR)/,$$(subst -,/,%.c)) $(BUILD_DIR)/test
	$(TESTING_CC) $(TESTING_C_FLAGS) -c $< -o $@ -I stage2 

$(BUILD_DIR)/test/%.o: $$(addprefix $(ROOT_DIR)/,$$(subst -,/,%.asm)) $(BUILD_DIR)/test
	$(ASM) $< -Wall -Werror -felf32 -o $@

$(BUILD_DIR)/test/%.o: $(ROOT_DIR)/test/%.cc $(BUILD_DIR)/test
	$(TESTING_CXX) $(TESTING_CXX_FLAGS) -c $< -o $@ -I stage2

$(BUILD_DIR)/test:
	mkdir -p $(BUILD_DIR)/test