dd if=/dev/zero of=$1/disk.dd bs=1048576 count=128
# To create partitions, pipe input to fdisk, bc idk how to use anything else
# Makes GPT header with two partitions, one BIOS boot for stage 2 and one for the rest of the space
(
    echo g
    echo n p
    echo 1
    echo 2048
    echo +256
    echo t 1
    echo 4
    echo n p
    echo 2
    echo 4096
    echo 262110
    echo t
    echo 2
    echo 48
    echo w
) | fdisk $1/disk.dd

dd if=/dev/zero of=$1/ext2.dd bs=1048576 count=16
# TODO: Zig tools for these things to make it portable
mkfs.ext2 -L "Test EXT2 FS" $1/ext2.dd
mkdir $1/mount
sudo mount $1/ext2.dd $1/mount
sudo cp -a $2/. $1/mount/
sudo umount $1/mount
rm -r $1/mount

dd if=$1/stage1.bin of=$1/disk.dd conv=notrunc
dd if=$1/bootloader.bin of=$1/disk.dd seek=1048576 conv=notrunc bs=1
dd if=$1/ext2.dd of=$1/disk.dd conv=notrunc bs=1048576 seek=2 count=16 