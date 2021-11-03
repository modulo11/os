# Installation of arch

Using the [`archinstall`](https://wiki.archlinux.org/title/Archinstall) provided by the community.

```bash
python -m archinstall --config archinstall.json
```

## Important packages

```
chromium firefox
gparted hunspell-de hunspell-en syncthing
libreoffice-fresh libreoffice-fresh-de thunderbird thunderbird-i18n-de thunderbird-i18n-en-us gimp keepassxc
nmap remmina ansible packer-io
git jdk8-openjdk openjdk8-doc openjdk8-src maven android-tools android-udev
```

```
systemctl enable org.cups.cupsd.service
systemctl enable tlp
```

## Virtualization

```
pacman -Sy docker qemu vagrant virt-manager virtualbox virtualbox-guest-iso virtualbox-host-modules-arch
systemctl enable docker.service
gpasswd --add ${USER} docker
gpasswd --add ${USER} vboxusers
gpasswd --add ${USER} libvirt
```