CROSS_GCC := $(shell which i686-elf-gcc)
export CC := $(CROSS_GCC)
export LD := $(subst gcc,ld,$(CROSS_GCC))
export AS := $(subst gcc,as,$(CROSS_GCC))