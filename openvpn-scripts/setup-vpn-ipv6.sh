#!/bin/bash


# Setting up an IPv6 private tunnel
# Ref: https://community.openvpn.net/openvpn/wiki/IPv6

### Setup the VPN server with a static IPv6 Address



### Modify Server.conf and client.conf files

# On both client and server, set protocol to udp6
echo -e "Set Protocol: proto udp6"

# Provisioning a subnet other than a /64 is possible, but complicated
echo -e "Set Server: server-ipv6 2001:db8:0:123::/64"

# Configure the tunnel properties
tun-ipv6
push tun-ipv6
ifconfig-ipv6 2001:db8:0:123::1 2001:db8:0:123::2


# This would expose the server-side network to the client
#push "route-ipv6 2001:aa:bb:cc::/64"
# This would expose Internet accessibility, using the current allocated public IP space
push "route-ipv6 2000::/3"




# Ensure any IPv6 rules are allowed through firewall rules

