#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

flock --exclusive /tmp/apt_from_docs.lock \
    apt install -y debootstrap qemu-utils

mkdir -p /var/lib/libvirt/images/min_dist
pushd /var/lib/libvirt/images/min_dist
qemu-img create debian_sid.img 2G

fdisk debian_sid.img << "EOF"
n
p
1


a
w
EOF

DISK_DEV=`flock --exclusive /tmp/losetup_get_new_dev.lock losetup -f --show "debian_sid.img"`

partprobe ${DISK_DEV}
mkfs.ext4 -F ${DISK_DEV}p1
mkdir -p /mnt/debian_sid
mount -v ${DISK_DEV}p1 /mnt/debian_sid

debootstrap --verbose --include=sudo,locales,nano,wget,grub-pc --arch amd64 sid /mnt/debian_sid http://ftp.pt.debian.org/debian/

cat > /mnt/debian_sid/etc/fstab << "EOF"
/dev/sda1       /               ext4        defaults        0       1
EOF

cat > /mnt/debian_sid/etc/apt/sources.list << "EOF"
deb http://ftp.pt.debian.org/debian sid main contrib non-free
deb-src http://ftp.pt.debian.org/debian sid main contrib non-free
EOF

cat > /mnt/debian_sid/root/postinst.sh << "EOF"
#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

cat > /etc/hostname << "OEF"
debian-sid
OEF

cat > /etc/default/locale << OEF
LANG=en_US.UTF-8
OEF

cat > /etc/locale.gen << OEF
en_US.UTF-8 UTF-8
OEF

locale-gen

apt update

passwd << "OEF"
admin
admin
OEF

apt -y install linux-image-amd64
#apt -y install firmware-linux firmware-ralink firmware-realtek firmware-atheros ssh
apt clean

sed -i 's/^#GRUB_TERMINAL.*/GRUB_TERMINAL="serial console"/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="console=ttyS0"/' /etc/default/grub
EOF

cat >> /mnt/debian_sid/root/postinst.sh << EOF
update-grub2
grub-install ${DISK_DEV} --modules="biosdisk part_msdos"
EOF

mount -v --bind /dev /mnt/debian_sid/dev
mount -vt proc proc /mnt/debian_sid/proc
mount -vt sysfs sysfs /mnt/debian_sid/sys
mount -vt tmpfs tmpfs /mnt/debian_sid/run

chroot /mnt/debian_sid /bin/bash /root/postinst.sh
chroot /mnt/debian_sid /bin/bash -c "rm -rf /root/postinst.sh"

popd

umount -v /mnt/debian_sid/run
umount -v /mnt/debian_sid/sys
umount -v /mnt/debian_sid/proc
umount -v /mnt/debian_sid/dev
umount -v /mnt/debian_sid/

losetup -d `losetup --all | grep debian_sid.img | awk '{print $1}' | sed 's/://'`
