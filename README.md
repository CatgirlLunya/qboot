# QBoot
QBoot is a somewhat simple bootloader designed as a learning experience for myself and others, focusing on code style and readability over performance to help others understand how bootloaders work. The name is short for QueerBoot, as the project is meant to be queer-friendly and the intended audience is queer developers, although all allies are welcome too!

## Dependencies
To build the bootloader, you need `nasm`, `fdisk`, and `dd` on BIOS, and `zig` for both BIOS and UEFI. The latest zig build the bootloader was compiled under is `0.12.0-dev.21+ac95cfe44`

For those unaware, to build a zig project you run `zig build` followed by the build step you would like to run, while in the directory containing build.zig. This generates output in the zig-out folder and maintains a cache in zig-cache for faster recompilation. For example, to run the `bios` build step, run `zig build bios`.

## Build Steps Available
The available build steps are:
- `bios`: builds the BIOS version of the bootloader and puts it into [disk.dd](zig-out/bios/disk.dd), which is a GPT configured disk made in [make_bios_disk.sh](scripts/make_bios_disk.sh)
- `run-bios`: does the same as `bios` but runs it using qemu. This uses `qemu-system-x86_64`, and uses 4 processors, 256 MB of RAM, and sets the time to the local time.
- `debug-bios`: does the same as `bios` but runs it in bochs, which requires `bochs` on your system compiled with graphical debugger installed. [The OSDev Wiki](https://wiki.osdev.org/Bochs) provides instructions for compiling bochs from source properly, which is often required.
- `uefi`: builds the UEFI version of the bootloader and put its into [BOOTX64.efi](zig-out/uefi/EFI/BOOT/BOOTX64.efi)
- `run-uefi`: does the same as `uefi` but runs it using qemu.
`qemu-system-x86_64` is used for qemu, and is configured to run with 4 processors, 256 MB of RAM, and the time set to the local time. Unfortunately, some bugs with OVMF exist and do not allow for using exception handling using qemu, so some UEFI functionality is only available on real hardware. 


