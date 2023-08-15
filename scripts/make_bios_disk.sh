dd if=/dev/zero of=$1/disk.dd bs=1048576 count=128
# To create partitions, pipe input to fdisk, bc idk how to use anything else
# Makes GPT header with two partitions, one BIOS boot for stage 2 and one for the rest of the space
(
    echo g
    echo n p
    echo 1
    echo 2048
    echo +128
    echo t 1
    echo 4
    echo n p
    echo 2
    echo 4096
    echo 260095
    echo w
) | fdisk $1/disk.dd

dd if=$1/stage1.bin of=$1/disk.dd conv=notrunc
dd if=$1/bootloader.bin of=$1/disk.dd seek=1048576 conv=notrunc bs=1