#!/usr/bin/env bash

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install tar cpio build-essential qemu-system-x86 git wget make -y
wget -c https://busybox.net/downloads/busybox-1.32.0.tar.bz2
tar xjf busybox-1.32.0.tar.bz2
make -C busybox-1.32.0 defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' busybox-1.32.0/.config
make -C busybox-1.32.0 -j16
make -C busybox-1.32.0 install
