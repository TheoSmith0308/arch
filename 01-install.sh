#!/bin/bash
clear
echo "    _             _       ___           _        _ _ "
echo "   / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | |"
echo "  / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _' | | |"
echo " / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |"
echo "/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|"
echo ""
echo "by Stephan Raabe (2023)"
echo "-----------------------------------------------------"
echo ""
echo "Important: Please make sure that you have followed the "
echo "manual steps in the README to partition the harddisc!"
echo "Warning: Run this script at your own risk."
echo ""

# ------------------------------------------------------
# Enter partition names
# ------------------------------------------------------
lsblk
read -p "Enter the name of the EFI partition (eg. sda1): " sda1
read -p "Enter the name of the ROOT partition (eg. sda2): " sda2
# read -p "Enter the name of the VM partition (keep it empty if not required): " sda3

# ------------------------------------------------------
# Sync time
# ------------------------------------------------------
timedatectl set-ntp true

# ------------------------------------------------------
# Format partitions
# ------------------------------------------------------
mkfs.fat -F 32 /dev/$sda1;
mkfs.btrfs -f /dev/$sda2
# mkfs.btrfs -f /dev/$sda3

# ------------------------------------------------------
# Mount points for btrfs
# ------------------------------------------------------
mount /dev/$sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
btrfs su cr /mnt/@images
umount /mnt

mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/$sda2 /mnt
mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,var/lib/libvirt/images,archroot}
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/$sda2 /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@log /dev/$sda2 /mnt/var/log
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@pkg /dev/$sda2 /mnt/var/cache/pacman/pkg
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@images /dev/$sda2 /mnt/var/lib/libvirt/images
mount /dev/$sda1 /mnt/boot/efi
# mkdir /mnt/windows
# mount /dev/$sda3 /mnt/windows

# ------------------------------------------------------
# Setting up mirrors for optimal download
# ------------------------------------------------------
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v20b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/ParallelDownloads = 5/ParallelDownloads = 2/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# ------------------------------------------------------
# Setting up $iso mirrors for faster download
# ------------------------------------------------------
reflector -c GB -c DE --sort rate -l 10 --save /etc/pacman.d/mirrorlist

# ------------------------------------------------------
# Install base packages
# ------------------------------------------------------
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode git vim reflector rsync openssh

# ------------------------------------------------------
# Generate fstab
# ------------------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# ------------------------------------------------------
# Install configuration scripts
# ------------------------------------------------------
cp 02-configuration.sh /mnt/archroot/
cp 3-yay.sh /mnt/archroot/
cp 4-zram.sh /mnt/archroot/
cp 5-timeshift.sh /mnt/archroot/
cp 6-preload.sh /mnt/archroot/
cp 7-gnome.sh /mnt/archroot/
cp 8-basepkglist.txt /mnt/archroot/
cp 9-snapshot.sh /mnt/archroot/

# ------------------------------------------------------
# Chroot to installed sytem
# ------------------------------------------------------

arch-chroot /mnt ./archroot/02-configuration.sh


