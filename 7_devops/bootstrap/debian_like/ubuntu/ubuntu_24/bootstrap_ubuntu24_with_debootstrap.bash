#!/bin/bash

#https://help.ubuntu.com/community/SerialConsoleHowto

set -o xtrace
set -o verbose
set -o errexit

flock --exclusive /tmp/apt_from_docs.lock \
    apt-get install -y qemu-utils xz-utils 7zip

mkdir -p /var/lib/libvirt/images/min_dist
pushd /var/lib/libvirt/images/min_dist
qemu-img create ubuntu_24.img 3G


fdisk ubuntu_24.img << "EOF"
n
p
1


a
w
EOF


DISK_DEV=`flock --exclusive /tmp/losetup_get_new_dev.lock losetup -f --show "ubuntu_24.img"`


partprobe ${DISK_DEV}
mkfs.ext4 -F ${DISK_DEV}p1
mkdir -p /mnt/ubuntu_24
mount -v ${DISK_DEV}p1 /mnt/ubuntu_24

debootstrap --verbose --include=sudo,locales,nano,wget,grub-pc --arch amd64 noble /mnt/ubuntu_24 http://pt.archive.ubuntu.com/ubuntu/


cat > /mnt/ubuntu_24/root/postinst.sh << "EOF"
#!/bin/bash


mkdir -p /run/systemd/resolve/
cat > /run/systemd/resolve/stub-resolv.conf << "EOFFFF"
nameserver 8.8.8.8
EOFFFF


cat > /etc/apt/sources.list << "EOFFFF"
# Main Ubuntu repositories
deb http://pt.archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb-src http://pt.archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse

# Updates repository
deb http://pt.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src http://pt.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse

# Security updates repository
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb-src http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse

# Backports (optional)
#deb http://pt.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
#deb-src http://pt.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
EOFFFF

apt update
apt -y upgrade

apt -y install linux-image-generic
apt -y install ssh
apt clean

sed -i 's/^#GRUB_TERMINAL.*/GRUB_TERMINAL="serial console"/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="console=ttyS0"/' /etc/default/grub


cat > /etc/init/ttyS0.conf << "EOFF"
start on stopped rc or RUNLEVEL=[12345]
stop on runlevel [!12345]

respawn
exec /sbin/getty -L 115200 ttyS0 vt102
EOFF

cat - > /etc/default/grub << "EOFF"
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8"
GRUB_TERMINAL="console serial"
GRUB_TERMINAL_OUTPUT="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
EOFF

cat - > /etc/fstab << "EOFEOF"
UUID=sda1 /               ext4    errors=remount-ro 0       1
EOFEOF

UUIDsda=`blkid | grep sda1 | awk '{print $2}' | sed 's/"//g'`
sed -i "s/UUID=sda1/$UUIDsda/" /etc/fstab
EOF
cat >> /mnt/ubuntu_24/root/postinst.sh << EOF
update-grub2
grub-install ${DISK_DEV} --modules="biosdisk part_msdos" --
sed -i 's/\/dev\/loop.*p1/\/dev\/sda1/g' /boot/grub/grub.cfg
sync
EOF

mount -v --bind /dev /mnt/ubuntu_24/dev
mount -vt proc proc /mnt/ubuntu_24/proc
mount -vt sysfs sysfs /mnt/ubuntu_24/sys
mount -vt tmpfs tmpfs /mnt/ubuntu_24/run


chroot /mnt/ubuntu_24 /bin/bash /root/postinst.sh
chroot /mnt/ubuntu_24 /bin/bash -c "rm -rf /root/postinst.sh"

popd

umount -v /mnt/ubuntu_24/run
umount -v /mnt/ubuntu_24/sys
umount -v /mnt/ubuntu_24/proc
umount -v /mnt/ubuntu_24/dev
umount -v /mnt/ubuntu_24/

losetup -d ${DISK_DEV}
