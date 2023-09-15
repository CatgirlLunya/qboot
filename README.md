# QBoot
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

## Screenshots
### BIOS build
![Screenshot of the BIOS build in QEMU](screenshots/bios.png?raw=true)
### UEFI build
![Screenshot of the UEFI build in QEMU](screenshots/uefi.png?raw=true)

