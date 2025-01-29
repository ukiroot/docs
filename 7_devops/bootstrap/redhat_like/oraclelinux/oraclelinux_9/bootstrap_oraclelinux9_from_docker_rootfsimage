# List of available images could be get by link:
# https://hub.docker.com/v2/namespaces/library/repositories/oraclelinux/tags?page_size=100&name=9-slim

set -o xtrace
set -o verbose
set -o errexit

apt-get install -y debootstrap qemu-utils docker.io

mkdir -p /var/lib/libvirt/images/min_dist
cd /var/lib/libvirt/images/min_dist

qemu-img create oraclelinux9.img 3G

fdisk oraclelinux9.img << "EOF"
n
p
1


a
w
EOF

DISK_DEV=`losetup -f --show "oraclelinux9.img"`

partprobe ${DISK_DEV}
mkfs.ext4 -F ${DISK_DEV}p1
mkdir -p /mnt/oraclelinux9
mount -v ${DISK_DEV}p1 /mnt/oraclelinux9

cd /mnt/oraclelinux9

docker run --pull always --rm  docker.io/library/oraclelinux:9-slim ls
docker save docker.io/library/oraclelinux:9-slim  > oraclelinux_9.tar

tar xvf *.tar
cat manifest.json | jq --raw-output '.[0].Layers[]' | grep blobs | while read LAYER; do
  tar xvf ${LAYER} -C ./
done
rm -rfv blobs/sha256/

mount -v --bind /dev /mnt/oraclelinux9/dev
mount -vt devpts devpts /mnt/oraclelinux9/dev/pts
mount -vt proc proc /mnt/oraclelinux9/proc
mount -vt tmpfs tmpfs /mnt/oraclelinux9/run
mount -vt sysfs sysfs /mnt/oraclelinux9/sys

cat > /mnt/oraclelinux9/root/postinst.sh << EOF

cat > /etc/fstab << "OEFFFF"
/dev/sda1       /               ext4        defaults        0       1
OEFFFF

sed -i '6s/enabled=0/enabled=1/g' /etc/yum.repos.d/uek-ol9.repo
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
microdnf install dnf
dnf install \
    kernel-uek \
    grub2-pc.x86_64 \
    passwd \
    iproute \
    dhcp-client

passwd << "OEFFFF"
admin
admin
OEFFFF

cat > /etc/default/grub << "OEFFFF"
GRUB_TERMINAL="serial console"
GRUB_CMDLINE_LINUX="net.ifnames=0 console=tty0 console=ttyS0,115200"
OEFFFF
grub2-install ${DISK_DEV} --modules="biosdisk part_msdos" --target=i386-pc
grub2-mkconfig -o /boot/grub2/grub.cfg
EOF

cat >> /mnt/oraclelinux9/root/postinst.sh << "EOF"
KERNEL_VERSION=`ls /boot/ | grep initramfs | tail -n1 | grep -Eo '[1-9].*' | sed 's/\.img//g'`
dracut --force --add-drivers ahci --add-drivers virtio_scsi --add-drivers sd_mod /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
EOF

chroot /mnt/oraclelinux9 /bin/bash /root/postinst.sh
chroot /mnt/oraclelinux9 /bin/bash -c "rm -vf /root/postinst.sh"

cd ~/
umount -v /mnt/oraclelinux9/dev/pts
umount -v /mnt/oraclelinux9/dev
umount -v /mnt/oraclelinux9/proc
umount -v /mnt/oraclelinux9/run
umount -v /mnt/oraclelinux9/sys
umount -v /mnt/oraclelinux9

losetup -d "${DISK_DEV}"
