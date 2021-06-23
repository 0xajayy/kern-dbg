#!/usr/bin/env bash

RED="\e[31m"
GREEN="\e[32m"
END="\e[0m"

# checking requirements
(which qemu-system-x86_64) > /dev/null
if [ $? -eq 0 ]
then
  echo -e " ${GREEN}[*] Requirements satisfied ${END}"
else
  echo -e " ${RED}[*] qemu not found run requirements.sh to install missing dependencies ${END}"
  exit
fi

# Edit kernel version to work with your desired kernel
export KERNEL=5.9.7
if [ -d "./linux-$KERNEL" ]
then
pushd fs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
popd
rm initramfs.cpio > /dev/null
gunzip initramfs.cpio.gz
qemu-system-x86_64 \
    -s \
    -m 64M \
    -nographic \
    -kernel linux-$KERNEL/arch/x86/boot/bzImage \
    -append "console=ttyS0 quiet loglevel=3 oops=panic panic=-1 nopti nokaslr min_addr=4096" \
    -no-reboot \
    -cpu qemu64 \
    -monitor /dev/null \
    -initrd "./initramfs.cpio" \
   -smp 2 \
   -smp cores=2 \
   -smp threads=1
else
echo -e " ${GREEN}[*] Downloading kernel $KERNEL ${END}"
wget -c https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.gz
if [ $? -eq 0 ]
then
  echo -e " ${GREEN}[*] Kernel downloaded successfully ${END}"
else
  echo -e " ${RED}[*] Kernel download error check kernel version ${END}"
  exit
fi
tar -xf linux-$KERNEL*

echo -e " ${GREEN}[+] Building kernel... ${END}"
make -C linux-$KERNEL defconfig
echo "CONFIG_NET_9P=y" >> linux-$KERNEL/.config
echo "CONFIG_NET_9P_DEBUG=n" >> linux-$KERNEL/.config
echo "CONFIG_9P_FS=y" >> linux-$KERNEL/.config
echo "CONFIG_9P_FS_POSIX_ACL=y" >> linux-$KERNEL/.config
echo "CONFIG_9P_FS_SECURITY=y" >> linux-$KERNEL/.config
echo "CONFIG_NET_9P_VIRTIO=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_PCI=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_BLK=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_BLK_SCSI=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_NET=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_CONSOLE=y" >> linux-$KERNEL/.config
echo "CONFIG_HW_RANDOM_VIRTIO=y" >> linux-$KERNEL/.config
echo "CONFIG_DRM_VIRTIO_GPU=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_PCI_LEGACY=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_BALLOON=y" >> linux-$KERNEL/.config
echo "CONFIG_VIRTIO_INPUT=y" >> linux-$KERNEL/.config
echo "CONFIG_CRYPTO_DEV_VIRTIO=y" >> linux-$KERNEL/.config
echo "CONFIG_BALLOON_COMPACTION=y" >> linux-$KERNEL/.config
echo "CONFIG_PCI=y" >> linux-$KERNEL/.config
echo "CONFIG_PCI_HOST_GENERIC=y" >> linux-$KERNEL/.config
echo "CONFIG_GDB_SCRIPTS=y" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_INFO=y" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_INFO_REDUCED=n" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_INFO_SPLIT=n" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_FS=y" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_INFO_DWARF4=y" >> linux-$KERNEL/.config
echo "CONFIG_DEBUG_INFO_BTF=n" >> linux-$KERNEL/.config
echo "CONFIG_FRAME_POINTER=y" >> linux-$KERNEL/.config
make -C linux-$KERNEL -j16 bzImage

cd fs
mkdir -p bin sbin etc proc sys usr/bin usr/sbin root home/kern
cd ..
cp -a busybox-1.32.0/_install/* fs

pushd fs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
popd
rm initramfs.cpio > /dev/null
gunzip initramfs.cpio.gz

qemu-system-x86_64 \
    -s \
    -m 64M \
    -nographic \
    -kernel linux-$KERNEL/arch/x86/boot/bzImage \
    -append "console=ttyS0 quiet loglevel=3 oops=panic panic=-1 nopti nokaslr min_addr=4096" \
    -no-reboot \
    -cpu qemu64 \
    -monitor /dev/null \
    -initrd "./initramfs.cpio" \
   -smp 2 \
   -smp cores=2 \
   -smp threads=1
fi
