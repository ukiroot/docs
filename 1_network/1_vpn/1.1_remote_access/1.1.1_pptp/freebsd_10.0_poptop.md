#### Domain name
```
hostname clineOS
cat > /etc/rc.conf << "EOF"
hostname=clineOS
EOF
```
#### DNS client settings
```
cat > /etc/resolv.conf << "EOF"
nameserver 8.8.8.8
EOF
```
#### Network interfaces configuration
```
ifconfig em0 192.0.2.1/24
ifconfig em1 192.168.0.1/24
ifconfig em1.100 create
ifconfig em1.100 192.168.100.1/24

cat >> /etc/rc.conf << "EOF"
ifconfig_em0="inet 192.0.2.1 netmask 255.255.255.0"
ifconfig_em1="inet 192.168.0.1 netmask 255.255.255.0"
vlans_em1=100
ifconfig_em1_100="inet 192.168.100.1/24"
EOF
```
#### Default route rule
```
route add default 192.0.2.100

cat >> /etc/rc.conf << "EOF"
defaultrouter="192.0.2.100"
EOF
```
#### Route rules
```
sysctl -w net.inet.ip.forwarding=1

cat >> /etc/rc.conf << "EOF"
gateway_enable=YES
EOF
```
#### PPTP configuration
```
pkg install --yes poptop

cat > /usr/local/etc/pptpd.conf << "EOF"
noipparam
listen 192.0.2.1
localip 10.255.254.0
remoteip 10.0.0.1-25
pidfile /var/run/pptpd.pid
EOF

cat > /etc/ppp/ppp.conf << "EOF"
pptp:
 set timeout 0
 set log phase chat connect lcp ipcp command
 set dial
 set login
 set ifaddr 10.255.254.0 10.0.0.1-10.0.0.25 255.255.255.0
 set accmap ffffffff
 enable mschapv2
 accept mschapv2
 enable mppe
 enable lqr
 enable dns
 accept dns
 allow mode direct
 disable ipv6cp
 enable proxy
EOF

cat > /etc/ppp/ppp.secret << "EOF"
lalka lolichan
bigbrother 1984
EOF

cat >> /etc/rc.conf << "EOF"
pptpd_enable=YES
EOF

service pptpd start
```
#### NAT rules
```
cat >> /etc/rc.conf << "EOF"
pf_enable=YES
pf_rules=/etc/pf.conf
pf_program=/sbin/pfctl
EOF

cat > /etc/pf.conf << "EOF"
rdr on em0 proto tcp from any to 192.0.2.1 port {80, 443} -> 192.168.100.2
rdr on em0 proto tcp from any to 192.0.2.1 port {25, 110, 143} -> 192.168.100.100
nat on em0 from any to any -> (em0)
EOF

service pf start
#pfctl -f  /etc/pf.conf
```

#### NTP
```
cat > /etc/ntp.conf << "EOF"
server 1.pool.ntp.org
restrict default ignore
restrict 1.pool.ntp.org nomodify noquery notrap
restrict 127.0.0.1 nomodify notrap
restrict 192.168.0.0 mask 255.255.255.0 nomodify notrap
restrict 192.168.100.0 mask 255.255.255.0 nomodify notrap
logfile /var/log/ntp.log
EOF

cat >> /etc/rc.conf << "EOF"
ntpd_enable=YES
ntpd_sync_on_start=YES
EOF

service ntpd start
```
#### DHCP server
```
pkg install --yes isc-dhcp43-server

cat > /usr/local/etc/dhcpd.conf << "EOF"
ddns-update-style none;
authoritative;
subnet 192.168.0.0 netmask 255.255.255.0 {
   option domain-name-servers 192.168.0.1;
   option routers 192.168.0.1;
   option ntp-servers 192.168.0.1;
   default-lease-time 86400;
   option domain-name "neverexist.org";
   range 192.168.0.2 192.168.0.100;
}
EOF

cat >> /etc/rc.conf << "EOF"
dhcpd_enable=YES
dhcpd_ifaces=em1
EOF

service isc-dhcpd start
```
#### DNS forwarding
```
pkg install --yes bind910

cat > /usr/local/etc/namedb/named.conf << "EOF"
options {
   directory       "/usr/local/etc/namedb/working";
   pid-file        "/var/run/named/pid";
   dump-file       "/var/dump/named_dump.db";
   statistics-file "/var/stats/named.stats";
   listen-on {192.168.0.1;192.168.100.1;};
   include "/usr/local/etc/namedb/auto_forward.conf";
};
EOF

cat >> /etc/rc.conf << "EOF"
named_enable=YES
named_auto_forward=YES
EOF

service named start
```
#### SSH server
```
sed 's/#ListenAddress\ 0.0.0.0/ListenAddress\ 192.0.2.1/' /etc/ssh/sshd_config | cat > /etc/ssh/sshd_config

cat >> /etc/rc.conf << "EOF"
sshd_enable=YES
EOF
service sshd start
```
#### Firewall ipv4
```
cat >> /etc/pf.conf << "EOF"
block in all
block out all

pass in on em1 from 192.168.0.0/24 to any
pass out on em1 from any to 192.168.0.0/24

pass in on em1.100 from 192.168.100.0/24 to any
pass out on em1.100 from any to 192.168.100.0/24

pass in on em0 inet proto tcp from any to 192.168.100.2 port {80, 443}
pass in on em0 inet proto tcp from any to 192.168.100.100 port {25, 110, 143}

pass in on em0 from any to 192.0.2.1
pass out on em0 from 192.0.2.1 to any

pass in on ng0 from any to any
pass out on ng0 from any to any
EOF
service pf restart
```
#### Firewall ipv6
```
###
```