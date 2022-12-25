#### PPTP configuration
```
pkg install --yes mpd5
cat > /usr/local/etc/mpd5/mpd.conf << "EOF"
pptp_vpn:
   set ippool add pool_pptp 10.0.0.1 10.0.0.10

   create bundle template B_pptp
   set ipcp ranges 10.255.255.0/32 ippool pool_pptp
   set ipcp dns 8.8.8.8

   set bundle enable compression
   set ccp yes mppc
   set mppc yes e128
   set bundle enable crypt-reqd
   set mppc yes stateless
        
   create link template L_pptp pptp
   set link action bundle B_pptp
   set link no pap eap
   set link yes chap

   set link mtu 1460
   set link keep-alive 10 75
   set link max-redial 0
   set pptp self 192.0.2.1
   set link enable incoming
EOF

cat >> /etc/rc.conf << "EOF"
mpd_enable=YES
EOF

/usr/local/etc/rc.d/mpd5 start
```