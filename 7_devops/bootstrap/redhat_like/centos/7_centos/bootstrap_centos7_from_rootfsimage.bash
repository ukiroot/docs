#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

apt-get install -y debootstrap qemu-utils

mkdir -p /var/lib/libvirt/images/min_dist
pushd /var/lib/libvirt/images/min_dist

qemu-img create centos_7.img 2G

fdisk centos_7.img << "EOF"
n
p
1


a
w
EOF

DISK_DEV=`losetup -f --show "centos_7.img"`

partprobe ${DISK_DEV}
mkfs.ext4 -F ${DISK_DEV}p1
mkdir -p /mnt/centos
mount -v ${DISK_DEV}p1 /mnt/centos

pushd /mnt/centos
wget https://download.openvz.org/contrib/template/precreated/centos-7-x86_64-minimal-20170709.tar.xz
tar xvf *.tar.xz

mount -v --bind /dev /mnt/centos/dev
mount -vt devpts devpts /mnt/centos/dev/pts
mount -vt proc proc /mnt/centos/proc
mount -vt tmpfs tmpfs /mnt/centos/run
mount -vt sysfs sysfs /mnt/centos/sys


cat > /mnt/centos/root/postinst.sh << "EOF"

set -o xtrace
set -o verbose
set -o errexit

cat > /etc/fstab << "EOFFF"
/dev/sda1       /               ext4        defaults        0       1
EOFFF

##CentOS Linux 7's end of life is June 30, 2024, so packages are available only on 'vault.centos.org':
cat > /etc/yum.repos.d/CentOS-Base.repo << "EOFFF"
[base]
name=CentOS-$releasever - Base
baseurl=http://vault.centos.org/7.9.2009/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-$releasever - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-$releasever - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-$releasever - Plus
baseurl=http://vault.centos.org/7.9.2009/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOFFF

EOF
cat >> /mnt/centos/root/postinst.sh << EOF
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
yum -y update
yum -y install kernel.x86_64
yum -y install grub2.x86_64
####Do not mount install grub2-efi-modules for install grub in Non-UEFI mode
#yum -y install grub2-efi-modules
# --target=i386-pc for legacy in Non-UEFI mode
grub2-install ${DISK_DEV} --modules="biosdisk part_msdos" --target=i386-pc

cat > /etc/default/grub << "OEF"
GRUB_CMDLINE_LINUX="net.ifnames=0 console=ttyS0"
OEF
grub2-mkconfig -o /boot/grub2/grub.cfg
sed -i 's/\/dev\/loop.p1/\/dev\/sda1/g' /boot/grub2/grub.cfg
sed -i 's/linuxefi/linux/g' /boot/grub2/grub.cfg
sed -i 's/initrdefi/initrd/g' /boot/grub2/grub.cfg
EOF
cat >> /mnt/centos/root/postinst.sh << "EOF"

passwd << "OEFFFF"
admin
admin
OEFFFF

KERNEL_VERSION=`ls /boot/ | grep initramfs | tail -n1 | grep -Eo '[1-9].*' | sed 's/\.img//g'`
echo $KERNEL_VERSION
rm -fv /boot/initramfs*
dracut --force --add-drivers ahci --add-drivers virtio_scsi --add-drivers sd_mod /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
EOF

chroot /mnt/centos /bin/bash /root/postinst.sh
chroot /mnt/centos /bin/bash -c "rm -vf /root/postinst.sh"

popd
popd

umount -v /mnt/centos/dev/pts
umount -v /mnt/centos/dev
umount -v /mnt/centos/proc
umount -v /mnt/centos/run
umount -v /mnt/centos/sys
umount -v /mnt/centos

losetup -d "${DISK_DEV}"
