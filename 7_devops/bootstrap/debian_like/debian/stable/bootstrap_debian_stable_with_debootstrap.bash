#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

flock --exclusive /tmp/apt_from_docs.lock \
    apt-get install -y debootstrap qemu-utils

mkdir -p /var/lib/libvirt/images/min_dist
pushd /var/lib/libvirt/images/min_dist
qemu-img create debian_stable.img 1G


fdisk debian_stable.img << "EOF"
n
p
1


a
w
EOF


DISK_DEV=`flock --exclusive /tmp/losetup_get_new_dev.lock losetup -f --show "debian_stable.img"`


partprobe ${DISK_DEV}
mkfs.ext4 -F ${DISK_DEV}p1
mkdir -p /mnt/debian_stable
mount -v ${DISK_DEV}p1 /mnt/debian_stable

debootstrap --verbose --include=sudo,locales,nano,wget,grub-pc --arch amd64 stable /mnt/debian_stable http://ftp.pt.debian.org/debian/


cat > /mnt/debian_stable/etc/fstab << "EOF"
/dev/sda1       /               ext4        defaults        0       1
EOF

cat > /mnt/debian_stable/etc/apt/sources.list << "EOF"
deb http://ftp.pt.debian.org/debian stable main contrib non-free
deb-src http://ftp.pt.debian.org/debian stable main contrib non-free

deb http://ftp.debian.org/debian/ stable-updates main contrib non-free
deb-src http://ftp.debian.org/debian/ stable-updates main contrib non-free

deb http://ftp.debian.org/debian/ stable-backports main contrib non-free
deb-src http://ftp.debian.org/debian/ stable-backports main contrib non-free

deb http://ftp.pt.debian.org/debian-security stable/updates main contrib non-free
deb-src http://ftp.pt.debian.org/debian-security stable/updates main contrib non-free
EOF



cat > /mnt/debian_stable/root/postinst.sh << "EOF"
#!/bin/bash

apt-get update

passwd << "OEF"
admin
admin
OEF

cat > /etc/default/locale << OEF
LANG=en_US.UTF-8
OEF

cat > /etc/locale.gen << OEF
en_US.UTF-8 UTF-8
OEF

locale-gen

apt-get -y install linux-image-amd64
apt-get -y install firmware-linux firmware-ralink firmware-realtek firmware-atheros ssh
apt-get clean

sed -i 's/^#GRUB_TERMINAL.*/GRUB_TERMINAL="serial console"/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="console=ttyS0"/' /etc/default/grub

update-grub2
grub-install /dev/loop0 --modules="biosdisk part_msdos"
sed -i 's/\/dev\/loop0p1/\/dev\/sda1/g' /boot/grub/grub.cfg
sync
EOF


mount -v --bind /dev /mnt/debian_stable/dev
mount -vt proc proc /mnt/debian_stable/proc
mount -vt sysfs sysfs /mnt/debian_stable/sys
mount -vt tmpfs tmpfs /mnt/debian_stable/run


chroot /mnt/debian_stable /bin/bash /root/postinst.sh
chroot /mnt/debian_stable /bin/bash -c "rm -rf /root/postinst.sh"

popd

umount -v /mnt/debian_stable/run
umount -v /mnt/debian_stable/sys
umount -v /mnt/debian_stable/proc
umount -v /mnt/debian_stable/dev
umount -v /mnt/debian_stable/

losetup -d ${DISK_DEV}
