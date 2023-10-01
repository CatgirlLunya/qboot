# QBoot ![Lines of Code Badge](https://tokei.rs/b1/github/luna-nas/qboot)
QBoot is a somewhat simple bootloader designed as a learning experience for myself and others, focusing on code style and readability over performance to help others understand how bootloaders work. The name is short for QueerBoot, as the project is meant to be queer-friendly and the intended audience is queer developers, although all allies are welcome too!

## Dependencies
To build the bootloader, you need `nasm`, `fdisk`, and `dd` on BIOS, and `zig` for both BIOS and UEFI. The latest zig build the bootloader was compiled under is `0.12.0-dev.21+ac95cfe44`

For those unaware, to build a zig project you run `zig build` followed by the build step you would like to run, while in the directory containing build.zig. This generates output in the zig-out folder and maintains a cache in zig-cache for faster recompilation. For example, to run the `bios` build step, run `zig build bios`.

## Build Steps Available
The available build steps are:
- `bios`: builds the BIOS version of the bootloader and puts it into `zig-out/bios/disk.dd`, which is a GPT configured disk made in `scripts/make_bios_disk.sh`
- `run-bios`: does the same as `bios` but runs it using qemu.
- `debug-bios`: does the same as `bios` but runs it in bochs, which requires `bochs` on your system compiled with graphical debugger installed. [The OSDev Wiki](https://wiki.osdev.org/Bochs) provides instructions for compiling bochs from source properly, which is often required.
- `uefi`: builds the UEFI version of the bootloader and put its into `zig-out/uefi/EFI/BOOT/BOOTX64.efi`
- `run-uefi`: does the same as `uefi` but runs it using qemu.
- `package-uefi`: packages the UEFI build, normally just a file that is run raw in qemu, into a hard disk image with the executable in an EFI bootable partition. This disk is located at `zig-out/uefi/disk.dd`
`qemu-system-x86_64` is used for `run` commands, and is configured to run with 4 processors, 256 MB of RAM, and the time set to the local time. Unfortunately, some bugs with OVMF exist and do not allow for using exception handling using qemu, so some UEFI functionality is only available on real hardware. 
For burning the disk given by `package-uefi` or `bios` to a USB, I recommend using [Rufus](https://rufus.ie/en/) on Windows or `dd` on Linux. 

## Features
- Common
  - [x] Functional API that all platforms can use(see [api](stage2/api/))
  - [x] EXT2 filesystem parser(see [EXT2](stage2/common/fs/ext2.zig))
  - [x] GPT parser(see [GPT](stage2/common/gpt.zig))
  - [x] Config file parser(see [config](stage2/common/config.zig))
  - [x] Relatively portable build system(see [build](build.zig))
  - [ ] Elf File loader
  - [ ] Framebuffer
  - [ ] Pride theming
- BIOS
  - [x] Stage 1 that loads Stage 2(see [boot](stage1/boot.asm))
  - [x] ISRs, PIC, and IDT(see [IDT](stage2/arch/bios/asm/idt.zig) and [PIC](stage2/arch/bios/asm/pic.zig))
  - [x] Clock functionality using int 1Ah(see [clock](stage2/arch/bios/clock.zig))
  - [x] Memory Map using E820(see [memory_map](stage2/arch/bios/mm/memory_map.zig))
  - [x] Disk driver using int 13h extensions(see [disk](stage2/arch/bios/disk/disk.zig))
  - [x] Keyboard driver using PS/2(see [ps2](stage2/arch/bios/keyboard.zig)) 
  - [ ] Paging
- UEFI
  - [x] Protocol wrapper(see [protocol](stage2/arch/uefi/wrapper/protocol.zig))
  - [x] Matching functionality with BIOS
  - [x] Disk building script for use with real hardware(see [make_uefi_disk](scripts/make_uefi_disk.sh))
  - [ ] Exit boot services and jump to kernel

## Goals
- [ ] Reasonable API integration with zig STD(f.e. file system integration)
- [ ] More easily expandable build system(f.e. refactoring to make new targets easier and more automated)
- [ ] Zig host-side tools for build(f.e. zig versions of `dd`, `mkfs.ext2`, etc)
- [ ] More readable and documented code with proper references to manuals and documents

## Screenshots
### BIOS build
![Screenshot of the BIOS build in QEMU](screenshots/bios.png?raw=true)
### UEFI build
![Screenshot of the UEFI build in QEMU](screenshots/uefi.png?raw=true)

