# QBoot
QBoot is a somewhat simple bootloader designed as a learning experience for myself and others, focusing on code style and readability over performance to help others understand how bootloaders work. The name is short for QueerBoot, as the project is meant to be queer-friendly and the intended audience is queer developers, although all allies are welcome too!

## Dependencies
To build the bootloader, you need GNU make, along with `nasm`, `fdisk`, and a compiler in your path for `i686-elf`. You can make one using the instructions at [the OSDev Wiki](https://wiki.osdev.org/GCC_Cross-Compiler).

The Makefile also provides several targets to help debug the bootloader. These are entirely optional and are not needed for the build. 
- To run the bootloader, you will need `qemu-system`
- To debug it with bochs, you will need bochs compiled with gui debugger enabled. [The OSDev Wiki](https://wiki.osdev.org/Bochs) provides instructions for compiling bochs from source properly, which is often required.
- To generate clangd `compile_commands.json`, you need `bear`
- To run unit tests, you need to compile gtest using the instructions [here](https://stackoverflow.com/questions/38594169/how-to-reconfigure-google-test-for-a-32-bit-embedded-software), and install `gcc-multilib` and `g++-multilib`

## Building and Running
To build qboot, run
```bash
make
```
This generates disk.dd in the build directory, which can be run as a raw hard drive in qemu and bochs, and probably other emulators
***
To run qboot using qemu, run
```bash
make run
```
This runs [run.sh](scripts/run.sh), which uses `qemu-system-x86_64`.
***
To debug qboot, run 
```bash
make debug
```
This runs [bochs.sh](scripts/bochs.sh), which uses `bochs`
***
To generate `compile_commands.json` for clangd, run
```bash
make clangd 
```
This uses bear, and will clean and then make qboot
(You can do `make clangd_test` to generate files for testing, as that build system is separate)
***
To run the unit tests for the project, stored [here](test/), run
```bash
make run_tests
```
(Note: you can also build the tests using `make tests`, which outputs an executable as `build/run_tests`)
***
To clean the project, run
```bash
make clean
```
This will delete and then recreate the build directory, leaving it empty
