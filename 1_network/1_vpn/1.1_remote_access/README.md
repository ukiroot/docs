# VPN remote access

## VPN remote access stacks:

### [1.1.1 PPTP](1.1.1_pptp/)

Advantages:
* embedded client in Windows (since Windows 98);
* simplicity of client configuration on different systems Linux/Windows/BSD.

Minuses: 
* doesn't provide the required level of security.

### [1.1.2 L2PT/IPSEC](1.1.2_l2pt)

Advantages:
* embedded client in Windows (since Windows XP);
* provide the required level of security;
* supports SSL/TLS client authentication;

Minuses:
- difficult of configuration.

### [1.1.3 OpenVPN](1.1.3_openvpn)

Advantages:
* simplicity of configuration;
* application level OSI L7;
* provide the required level of security;
* supports SSL/TLS client authentication;
* supports integration with different services;
Minuses:
* required installation as new application.
