#!/bin/bash

# This script is intended to be run from a live Arch ISO
# WARNING: This will wipe /dev/vda without asking. Use only in a VM or test environment.

set -e

echo "==> Starting full Arch install for Rust development VM"

# Set variables
DISK="/dev/vda"
HOSTNAME="andy-dev2"
USERNAME="andy"
PASSWORD="andy"
DE_CHOICE="i3"  # options: i3, xfce, kde, none

# Partition disk (BIOS/MBR setup)
echo "==> Partitioning disk..."
parted -s $DISK mklabel msdos
parted -s $DISK mkpart primary ext4 1MiB 100%
mkfs.ext4 "${DISK}1"
mount "${DISK}1" /mnt

# Install base system
echo "==> Installing base system..."
pacstrap /mnt base linux linux-firmware sudo vim git networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure
arch-chroot /mnt /bin/bash <<EOF
echo "$HOSTNAME" > /etc/hostname
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers

# Enable networking
systemctl enable NetworkManager

# Install GRUB bootloader
pacman -Sy --noconfirm grub
grub-install --target=i386-pc --recheck $DISK
grub-mkconfig -o /boot/grub/grub.cfg

# Install desktop environment
case "$DE_CHOICE" in
  i3)
    pacman -S --noconfirm i3-wm i3status dmenu xterm lightdm lightdm-gtk-greeter
    systemctl enable lightdm
    ;;
  xfce)
    pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
    systemctl enable lightdm
    ;;
  kde)
    pacman -S --noconfirm plasma kde-applications sddm
    systemctl enable sddm
    ;;
  none)
    echo "No desktop environment selected"
    ;;
esac

EOF

echo "==> Unmounting and ready to reboot"
umount -R /mnt
echo "Install complete. You can now reboot into your Rust dev VM."
