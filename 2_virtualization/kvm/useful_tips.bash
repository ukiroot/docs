#Run VM
qemu-system-x86_64 -enable-kvm \
    -m 2048 -cpu host \
    -drive file=/var/lib/libvirt/images/min_dist/debian_7.img,format=raw \
    -net nic -net bridge,br=virbr0  \
    -display none \
    --daemonize \
    -device isa-serial,chardev=serial0 -chardev tcp:127.0.0.1:7777,server,nowait,telnet,id=serial0
#Connect to console
telnet 127.0.0.1 7777

#Run VM
nohup qemu-system-x86_64 -enable-kvm \
    -m 2048 -cpu host \
    -drive file=/var/lib/libvirt/images/min_dist/debian_7.img,format=raw \
    -net nic -net bridge,br=virbr0  \
    -display none \
    -serial unix:/tmp/serial.sock,server,nowait &> /dev/null &
#Attach console 
socat -,raw,echo=0,escape=0x0f unix-connect:/tmp/serial.sock
#Detach console Ctrl-o
