#### Domain name
```
set system host-name clineOS
commit
```
#### DNS client settings
```
set system name-server 8.8.8.8
commit
```
#### Network interfaces configuration
```
#LAN
set interfaces ethernet eth0 address 192.0.2.1/24
#WAN
set interfaces ethernet eth1 address 192.168.0.1/24
set interfaces ethernet eth1 vif 100 address 192.168.100.1/24
commit
```
#### Default route rule
```
set protocols static route 0.0.0.0/0 next-hop 192.0.2.100
commit
```
#### Route rules
```
#Not requred. Enabled by default
```
#### PPTP configuration
```
set vpn pptp remote-access authentication require mschap-v2
set vpn pptp remote-access authentication local-users username bigbrother password 1984
set vpn pptp remote-access authentication local-users username bigbrother static-ip 10.0.0.1
set vpn pptp remote-access authentication local-users username lalka password lolichan
set vpn pptp remote-access authentication local-users username lalka static-ip 10.0.0.2
set vpn pptp remote-access authentication mode local
set vpn pptp remote-access client-ip-pool start 10.0.0.1
set vpn pptp remote-access client-ip-pool stop 10.0.0.25
set vpn pptp remote-access dns-servers server-1 8.8.8.8
set vpn pptp remote-access outside-address 192.0.2.1
commit
```
#### NAT rules
```
#DNAT
set nat destination rule 10 destination address 192.0.2.1
set nat destination rule 10 destination port 80,443
set nat destination rule 10 inbound-interface eth0
set nat destination rule 10 protocol tcp
set nat destination rule 10 translation address 192.168.100.2
commit
set nat destination rule 20 destination address 192.0.2.1
set nat destination rule 20 destination port 25,110,143
set nat destination rule 20 inbound-interface eth0
set nat destination rule 20 protocol tcp
set nat destination rule 20 translation address 192.168.100.100
commit
#SNAT
set nat source rule 100 outbound-interface eth0
set nat source rule 100 translation address masquerade
commit
```
#### NTP
```
#Only client mode
set system ntp server 0.pool.ntp.org
commit
```
#### DHCP server
```
set service dhcp-server shared-network-name DHCP-SERV subnet 192.168.0.0/24 default-router 192.168.0.1
set service dhcp-server shared-network-name DHCP-SERV subnet 192.168.0.0/24 dns-server 192.168.0.1
set service dhcp-server shared-network-name DHCP-SERV subnet 192.168.0.0/24 ntp-server 192.168.0.1
set service dhcp-server shared-network-name DHCP-SERV subnet 192.168.0.0/24 start 192.168.0.2 stop 192.168.0.100
set service dhcp-server shared-network-name DHCP-SERV subnet 192.168.0.0/24 domain-name neverexist.org
commit
```
#### DNS forwarding
```
set service dns forwarding system
set service dns forwarding listen-on eth1
commit
```
#### SSH server
```
set service ssh listen-address 192.168.0.1
commit
```
#### Firewall ipv4
```
set firewall name IN-WAN default-action drop
#DNAT
set firewall name IN-WAN rule 10 action accept
set firewall name IN-WAN rule 10 destination address 192.168.100.2
set firewall name IN-WAN rule 10 destination port 80,443
set firewall name IN-WAN rule 10 protocol tcp
set firewall name IN-WAN rule 20 action accept
set firewall name IN-WAN rule 20 destination address 192.168.100.2
set firewall name IN-WAN rule 20 destination port 25,110,143
set firewall name IN-WAN rule 20 protocol tcp
#Allow packets for connections that was initiated from LAB to WAN
set firewall name IN-WAN rule 100 action accept
set firewall name IN-WAN rule 100 state established enable
set firewall name IN-WAN rule 100 state related enable
commit
set firewall name LOCAL-WAN default-action drop
#(PPTP)	
set firewall name LOCAL-WAN rule 1 action accept
set firewall name LOCAL-WAN rule 1 destination port 1723
set firewall name LOCAL-WAN rule 1 protocol tcp
#GRE
set firewall name LOCAL-WAN rule 2 protocol gre
set firewall name LOCAL-WAN rule 2 action accept
#DNS
set firewall name LOCAL-WAN rule 3 action accept
set firewall name LOCAL-WAN rule 3 source port 53,123
set firewall name LOCAL-WAN rule 3 protocol udp
#HTTP/HTTPS
set firewall name LOCAL-WAN rule 4 action accept
set firewall name LOCAL-WAN rule 4 source port 80,443
set firewall name LOCAL-WAN rule 4 protocol tcp
commit
#LAN
set firewall name IN-LAN default-action drop
set firewall name IN-LAN rule 100 action accept
set firewall name IN-LAN rule 100 source address 192.168.0.0/24
commit
set firewall name IN-VLAN100 default-action drop
set firewall name IN-VLAN100 rule 100 action accept
set firewall name IN-VLAN100 rule 100 source address 192.168.100.0/24
commit
set interfaces ethernet eth0 firewall in name IN-WAN
set interfaces ethernet eth0 firewall local name LOCAL-WAN
set interfaces ethernet eth1 firewall in name IN-LAN
set interfaces ethernet eth1 vif 100 firewall in name IN-VLAN100
commit
```
#### Firewall ipv6
```
set firewall ipv6-name BLOCK-IPV6 default-action drop
commit
set interfaces ethernet eth0 firewall out ipv6-name BLOCK-IPV6
set interfaces ethernet eth0 firewall local ipv6-name BLOCK-IPV6
set interfaces ethernet eth0 firewall in ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 firewall out ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 firewall local ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 firewall in ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 vif 100 firewall in ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 vif 100 firewall local ipv6-name BLOCK-IPV6
set interfaces ethernet eth1 vif 100 firewall out ipv6-name BLOCK-IPV6
commit
```
#### Save configuration to permanent
```
save
```