dd if=/dev/zero of=$2/disk.dd bs=1048576 count=128

parted -s -a minimal $2/disk.dd mklabel gpt
parted -s -a minimal $2/disk.dd mkpart primary fat32 1MiB 65MiB
parted -s -a minimal $2/disk.dd set 1 boot on

dd if=/dev/zero of=$2/temp_uefi_fs.dd bs=1048576 count=64
mformat -i $2/temp_uefi_fs.dd -F

mcopy $1 -s -i $2/temp_uefi_fs.dd ::/

dd if=$2/temp_uefi_fs.dd of=$2/disk.dd bs=1048576 count=64 seek=1 conv=notrunc
rm $2/temp_uefi_fs.dd