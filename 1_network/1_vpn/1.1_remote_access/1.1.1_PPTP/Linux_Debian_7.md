#### Domain name
```
hostname clineOS

#Set permanent hostname. After reboot setting will be applyed
cat > /etc/hostname << "EOF"
clineOS
EOF
```
#### DNS client settings
```
#Set DNS server
cat >  /etc/resolv.conf << "EOF"
nameserver 8.8.8.8
EOF
```
#### Network interfaces configuration
```
#Configuration of public network interface
ip addr add 192.0.2.1/24 broadcast 192.0.2.255 dev eth0
ip link set up eth0
#Configuration of private network interfate
ip addr add 192.168.0.1/24 broadcast 192.168.0.255 dev eth1
ip link set up eth1
#Add private virtual network interface eth1.100 which process packages with tag VLAN100
ip link add link eth1 name eth1.100 type vlan id 100
ip addr add 192.168.100.1/24 broadcast 192.168.100.255 dev eth1.100
ip link set up eth1.100

#Save network setting to configuration file. After reboot setting will be applyed
cat > /etc/network/interfaces << "EOF"
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 192.0.2.1
netmask 255.255.255.0
gateway 192.0.2.100

auto eth1
iface eth1 inet static
address 192.168.0.1
netmask 255.255.255.0

auto eth1.100
iface eth1.100 inet static
address 192.168.100.1
netmask 255.255.255.0
vlan_raw_device eth1
EOF
```
#### Default route rule
```
ip route add 0.0.0.0/0 via 192.0.2.100
```
#### Route rules
```
#Enable forwarding
sysctl -w net.ipv4.ip_forward=1
cat >> /etc/sysctl.conf << "EOF"
net.ipv4.ip_forward = 1
EOF
```
#### PPTP configuration
```
apt-get install pptpd -y

cat > /etc/pptpd.conf << "EOF"
option /etc/ppp/pptpd-options
localip 10.255.254.0
remoteip 10.0.0.1-25
listen 192.0.2.1
EOF

cat > /etc/ppp/pptpd-options << "EOF"
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
nodefaultroute
lock
nobsdcomp
novj
novjccomp
nologfd
EOF

#     client          server          secret      IP addresses
cat > /etc/ppp/chap-secrets << "EOF"
bigbrother   pptpd   1984      10.0.0.1
lalka        pptpd   lolichan  10.0.0.2
EOF

/etc/init.d/pptpd restart
```
#### NAT rules
```
#DNAT rules
iptables -t nat -A PREROUTING -d 192.0.2.1/32 -i eth0 -p tcp -m multiport --dports 80,443  -j DNAT --to-destination 192.168.100.2
iptables -t nat -A PREROUTING -d 192.0.2.1/32 -i eth0 -p tcp -m multiport --dports 25,110,143 -j DNAT --to-destination 192.168.100.100
#SNAT rules
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
#### NTP
```
apt-get install openntpd -y

cat > /etc/openntpd/ntpd.conf << EOF
listen on 192.168.0.1
servers 1.pool.ntp.org
EOF

/etc/init.d/openntpd restart
```
#### DHCP servers
```
apt-get install isc-dhcp-server -y

cat > /etc/dhcp/dhcpd.conf << "EOF"
ddns-update-style none;
authoritative;
subnet 192.168.0.0 netmask 255.255.255.0 {
   option domain-name-servers 192.168.0.1;
   option routers 192.168.0.1;
   option ntp-servers 192.168.0.1;
   default-lease-time 86400;
   max-lease-time 86400;
   option domain-name "neverexist.org";
   range 192.168.0.2 192.168.0.100;
}
EOF
/etc/init.d/isc-dhcp-server restart
```
#### DNS forwarding
```
apt-get install dnsmasq -y

cat > /etc/dnsmasq.conf << "EOF"
log-facility=/var/log/dnsmasq.log
no-poll
edns-packet-max=4096
interface=eth1
cache-size=150
resolv-file=/etc/resolv.conf
EOF

/etc/init.d/dnsmasq restart
```
#### SSH servers
```
apt-get install ssh -y

#Bind SSH only to 192.0.2.1
sed -i 's/#ListenAddress\ 0.0.0.0/ListenAddress\ 192.0.2.1/' /etc/ssh/sshd_config

/etc/init.d/ssh restart
```
#### Firewall ipv4
```
#Firewall Rules ipv4
#For DNAT
iptables -t filter -A FORWARD -i eth0 -p tcp -m multiport --dport 80,443 -d 192.168.100.2  -j ACCEPT
iptables -t filter -A FORWARD -i eth0 -p tcp -m multiport --dport 25,110,143 -d 192.168.100.100  -j ACCEPT

#Rules from LAN to WAN
iptables -t filter -A FORWARD -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
#Drop in other cases
iptables -t filter -A FORWARD -i eth0 -j DROP

#LAN
iptables -t filter -A FORWARD -i eth1 -s 192.168.0.0/24 -j ACCEPT
iptables -t filter -A FORWARD -i eth1 -j DROP
iptables -t filter -A FORWARD -i eth1.100 -s 192.168.100.0/24 -j ACCEPT
iptables -t filter -A FORWARD -i eth1.100 -j DROP

#Access PPTP stack
iptables -t filter -A INPUT -i eth0 -p tcp --dport 1723 -j ACCEPT
iptables -t filter -A INPUT -i eth0 -p gre -j ACCEPT
#Remote access by SSH
iptables -t filter -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -t filter -A INPUT -i eth0 -p tcp -m multiport --sport 80,443 -j ACCEPT
#For local service DNS/NTP
iptables -t filter -A INPUT -i eth0 -p udp -m multiport --sport 53,123 -j ACCEPT
#Final default rule for INPUT
iptables -t filter -A INPUT -i eth0 -j DROP

#Save netfilter rules to file /etc/iptables.rule
iptables-save > /etc/iptables.rule
sed -i 's/^exit 0/iptables-restore < \/etc\/iptables.rule\nexit 0/' /etc/rc.local
```
#### Firewall ipv6
```
########13_START
#Firewall Rules IPV6
ip6tables -t filter -A FORWARD -j DROP
ip6tables -t filter -A INPUT -j DROP
ip6tables -t filter -A OUTPUT -j DROP

#Restore rules for IPV6
sed -i 's/^exit 0/ip6tables-restore < \/etc\/ip6tables.rule\nexit 0/' /etc/rc.local
ip6tables-save > /etc/ip6tables.rule
```