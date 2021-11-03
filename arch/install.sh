#!/usr/bin/env bash

set -xeu pipefail

main() {
  DISK="/dev/sda"

  read -p "Enter disk [/dev/sda]: " DISK
  read -p "Enter hostname: " HOSTNAME
  read -p "Enter username: " USERNAME
  read -s -p "Enter password: " PASSWORD
  echo ""

  UEFI=0
  ENCYPTION=0

  if $(efivar --list >/dev/null 2>&1); then
    echo "UEFI detected"
    UEFI=1
  fi

  partition
  install
  finish
}

partition() {
  if [[ ${ENCYPTION} -eq 1 ]]; then
    partition_encrypted
  else
    partition_unencrypted
  fi
}

partition_unencrypted() {
  PARTITION="${DISK}1"

  parted ${DISK} mklabel msdos
  parted ${DISK} mkpart primary 1 100%
  mkfs.ext4 ${PARTITION}
  mount ${PARTITION} /mnt
}

partition_encrypted() {
  BOOT_PARTITION="${DISK}1"
  ROOT_PARTITION="${DISK}2"

  parted ${DISK} mklabel gpt 
  parted ${DISK} mkpart primary fat32 1MiB 265MiB
  parted ${DISK} set 1 esp on
  parted ${DISK} mkpart primary ext4 265MiB 100%

  dd if=/dev/urandom of=${ROOT_PARTITION} bs=512 count=40960
  cryptsetup luksFormat ${ROOT_PARTITION}
  cryptsetup --type luks open ${ROOT_PARTITION} root

  mkfs.fat -F 32 ${BOOT_PARTITION}
  mkfs.ext4 /dev/mapper/root

  mount /dev/mapper/root /mnt
  mkdir /mnt/boot
  mount ${BOOT_PARTITION} /mnt/boot

  ROOT_UUID=$(blkid -s UUID -o value ${ROOT_PARTITION})
}

setup_user() {
  export USERNAME
  export PASSWORD

  arch-chroot /mnt /bin/bash -x <<'EOF'
  echo root:${PASSWORD} | chpasswd
  groupadd ${USERNAME}
  useradd --create-home --gid ${USERNAME} --groups wheel --shell /bin/bash ${USERNAME}
  echo ${USERNAME}:${PASSWORD} | chpasswd
EOF
}

install() {
  pacstrap /mnt base linux linux-firmware
  genfstab -U /mnt >> /mnt/etc/fstab

  pacman "sudo"
  setup_user

  # Setup locales/timezone
  sed -i s/^"#de_DE.UTF-8 UTF-8"/"de_DE.UTF-8 UTF-8"/g /mnt/etc/locale.gen
  sed -i s/^"#en_US.UTF-8 UTF-8"/"en_US.UTF-8 UTF-8"/g /mnt/etc/locale.gen
  chroot "locale-gen"
  echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
  echo "KEYMAP=de" > /mnt/etc/vconsole.conf
  # Setup sudoers
  sed -i "/%wheel ALL=(ALL) ALL/s/^#//" /mnt/etc/sudoers
  ln -s /usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime
  chroot "hwclock --systohc --utc"
  # Setup hostname
  echo ${HOSTNAME} > /mnt/etc/hostname

  install_bootloader
  install_base
  install_gnome

  config_dhcp
}

install_bootloader() {
  pacman "grub"

  if [[ ${ENCYPTION} -eq 1 ]]; then
    sed -i s/^GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${ROOT_UUID}:root\"/g /mnt/etc/default/grub
    sed -i s/^HOOKS.*/HOOKS="\"base udev autodetect modconf block keymap encrypt filesystems keyboard fsck"\"/g /mnt/etc/mkinitcpio.conf
  fi

  if [[ ${UEFI} -eq 1 ]]; then
  pacman "efibootmgr"
  chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
  else
    chroot "grub-install --recheck --target=i386-pc ${DISK}"
  fi

  chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

install_base() {
  # Basic stuff
  pacman "vim bash-completion intel-ucode"
  # Xorg
  pacman "xorg-server"
  # Fonts
  # pacman "ttf-dejavu"
  # pacman "ttf-liberation"
  # pacman "noto-fonts"
  pacman "ttf-croscore"
}

install_gnome() {
  pacman "baobab cheese eog evince file-roller gdm gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-contacts gnome-control-center gnome-dictionary gnome-disk-utility gnome-font-viewer gnome-keyring gnome-logs gnome-maps gnome-menus gnome-photos gnome-screenshot gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-terminal gnome-todo gnome-weather gnome-tweaks gvfs gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb mousetweaks mutter nautilus networkmanager simple-scan sushi totem xdg-user-dirs-gtk"
  # Utilities
  pacman "acpi_call cups cups-pdf ntfs-3g openssh pwgen rsync tlp tlp-rdw wget x86_energy_perf_policy alsa-utils"

  chroot "systemctl enable cups"
  chroot "systemctl enable tlp"
  chroot "systemctl enable gdm.service"
  chroot "systemctl enable NetworkManager.service"

  # See https://bugs.archlinux.org/task/63706?project=1&string=systemd
  chroot "chage -M -1 gdm"
}

vbox_guest() {
  pacman "virtualbox-guest-utils virtualbox-guest-modules-arch"
  chroot "systemctl enable vboxservice.service"
}

config_dhcp() {
  # Enable sending hostname via DHCP
  echo "send host-name = pick-first-value(gethostname(), "ISC-dhclient");" > /mnt/etc/dhclient.conf
  echo "send fqdn.fqdn = pick-first-value(gethostname(), "ISC-dhclient");" > /mnt/etc/dhclient6.conf
}

finish() {
  umount -R /mnt

  if [[ ${ENCYPTION} -eq 1 ]]; then
    cryptsetup close root
  fi

  echo "Installation finished!"
}

chroot() {
  arch-chroot /mnt $1
}

pacman() {
  chroot "pacman -Sy --quiet --noconfirm $1"
}

main
