#!/bin/bash
#Total size 335Mb
#RS232 and VGA

set -o xtrace
set -o verbose
set -o errexit

flock --exclusive /tmp/apt_from_docs.lock \
    apt-get install -y debootstrap qemu-utils

mkdir -p /var/lib/libvirt/images/min_dist
pushd /var/lib/libvirt/images/min_dist

rm -fv debian_7.img
qemu-img create debian_7.img 1G
fdisk debian_7.img << "EOF"
n
p
1


a
w
EOF

modprobe nbd max_part=15
qemu-nbd -f raw  -c /dev/nbd0 debian_7.img
partprobe /dev/nbd0

#use ext2 because the latest ext3/ext4 features may not be fully compatible with kernel 3.2.
mkfs.ext2 /dev/nbd0p1
mkdir -p  /mnt/debian_7
mount -v /dev/nbd0p1 /mnt/debian_7

debootstrap --verbose --include=sudo,nano,wget,grub-pc,linux-image-amd64 --arch amd64 wheezy /mnt/debian_7 http://archive.debian.org/debian/

cat > /mnt/debian_7/etc/fstab << "EOF"
/dev/sda1       /               ext2        defaults        0       1
EOF

cat > /mnt/debian_7/etc/apt/sources.list << "EOF"
deb http://archive.debian.org/debian/ wheezy main contrib non-free
deb http://archive.debian.org/debian/ wheezy-backports main contrib non-free
# Debian Wheezy (Debian 7) reached its end of life (EOL) on May 31, 2018
#deb http://archive.debian.org/debian/ wheezy/updates main contrib non-free
EOF

cat > /mnt/debian_7/root/postinst.sh << "EOF"
#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

cat > /etc/hostname << "OEF"
debian-7
OEF

passwd << "OEF"
admin
admin
OEF

#apt-get -y install firmware-linux firmware-ralink firmware-realtek
#apt-get clean

sed -i 's/^#T0:23.*/T0:23:respawn:\/sbin\/getty -L ttyS0 115200 vt100/' /etc/inittab
sed -i 's/^#GRUB_TERMINAL.*/GRUB_TERMINAL="serial console"/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="console=ttyS0"/' /etc/default/grub

grub-install /dev/nbd0 --modules="biosdisk part_msdos" --force || true
grub-mkconfig -o /boot/grub/grub.cfg
sed -i 's/\/dev\/nbd0p1/\/re/g' /boot/grub/grub.cfg
sync
EOF

mount -v --bind /dev /mnt/debian_7/dev
mount -vt proc proc /mnt/debian_7/proc
mount -vt sysfs sysfs /mnt/debian_7/sys
mount -vt tmpfs tmpfs /mnt/debian_7/run

chroot /mnt/debian_7 /bin/bash /root/postinst.sh
chroot /mnt/debian_7 /bin/bash -c "rm -rf /root/postinst.sh"

popd

umount -v /mnt/debian_7/run
umount -v /mnt/debian_7/sys
umount -v /mnt/debian_7/proc
umount -v /mnt/debian_7/dev
umount -v /mnt/debian_7/

qemu-nbd -d /dev/nbd0
rmmod nbd
