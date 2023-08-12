dd if=/dev/zero of=$1/disk.dd bs=1048576 count=128

parted -s -a minimal $1/disk.dd mklabel gpt
parted -s -a minimal $1/disk.dd mkpart primary fat32 1MiB 64MiB
parted -s -a minimal $1/disk.dd set 1 boot on

dd if=/dev/zero of=$1/temp_uefi_fs.dd bs=1048576 count=64
mformat -i $1/temp_uefi_fs.dd -F

mcopy $1/uefi64.efi -i $1/temp_uefi_fs.dd ::/

dd if=$1/temp_uefi_fs.dd of=$1/disk.dd bs=1048576 count=64 seek=1 conv=notrunc