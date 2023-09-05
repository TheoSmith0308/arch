#!/bin/bash
clear
echo "    _             _       ___           _        _ _ "
echo "   / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | |"
echo "  / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _' | | |"
echo " / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |"
echo "/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|"
echo ""
echo "(2023)"
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
read -p "Enter the name of the EFI partition (eg. sda1): " vda1
read -p "Enter the name of the ROOT partition (eg. sda2): " vda2
read -p "Enter the name of the windows partition (keep it empty if not required): " sda3

# ------------------------------------------------------
# Sync time
# ------------------------------------------------------
timedatectl set-ntp true

# ------------------------------------------------------
# Format partitions
# ------------------------------------------------------
mkfs.fat -F 32 /dev/$sda1
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
btrfs su cr /mnt/@snapshots
umount /mnt

mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=256 /dev/$sda2 /mnt
mkdir -p /mnt/{efi,home,var/log,var/cache/pacman/pkg,var/lib/libvirt/images,.snapshots,.btrfsroot}
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolis=257 /dev/$sda2 /mnt/home
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=258 /dev/$sda2 /mnt/var/log
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=259 /dev/$sda2 /mnt/var/cache/pacman/pkg
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=260 /dev/$sda2 /mnt/var/lib/libvirt/images
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=261 /dev/$sda2 /mnt/.snapshots
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvolid=5 /dev/$sda2 /mnt/.btrfsroot
mount /dev/$sda1 /mnt/efi
# mkdir /mnt/windows
# mount /dev/$sda3 /mnt/windows

# ------------------------------------------------------
# Setting up mirrors for optimal download
# ------------------------------------------------------
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/ParallelDownloads = 5/ParallelDownloads = 3/' /etc/pacman.conf
# pacman -S --noconfirm --needed reflector rsync
# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# ------------------------------------------------------
# Run reflector to update mirrorlist
# ------------------------------------------------------
reflector -c ZA --sort rate -p https -p http -l 10 --save /etc/pacman.d/mirrorlist
pacman -Sy

# ------------------------------------------------------
# Install base packages
# ------------------------------------------------------
pacstrap -K /mnt base btrfs-progs git intel-ucode linux linux-firmware openssh pacman-contrib reflector rsync vim

# ------------------------------------------------------
# Generate fstab
# ------------------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# ------------------------------------------------------
# Install configuration scripts
# ------------------------------------------------------
mkdir /mnt/archinstall
cp -r ./ /mnt/archinstall/
cp pkgs-x86_64.txt /mnt/

# ------------------------------------------------------
# Chroot to installed sytem
# ------------------------------------------------------
arch-chroot /mnt ./archinstall/2-configuration.sh
