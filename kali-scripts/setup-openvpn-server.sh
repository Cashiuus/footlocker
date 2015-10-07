#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: setup-openvpn-server.sh       (Update: 10-05-2015 #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
# Usage: Setup OpenVPN Server and prep all certs needed.      #
#                                                             #
#                                                             #
#                                                             #
#                                                             #
#-------------------------------------------------------------#
# OpenVPN Hardening Cheat Sheet: http://darizotas.blogspot.com/2014/04/openvpn-hardening-cheat-sheet.html
#

# ----- EDIT VARIABLES ----- #
VPN_PREP="${HOME}/vpn-setup"
VPN_SERVER='192.168.1.52'
VPN_PORT='443'
CLIENT_NAME="client1"
VPN_SUBNET="10.9.8.0"
# -------------------------- #

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


sudo apt-get install openvpn openssl -y
service openvpn stop
openvpn --version

if [[ ! -d "$HOME/easy-rsa" ]]; then
	git clone git://github.com/OpenVPN/easy-rsa
fi

[[ ! -d "${VPN_PREP}" ]] && mkdir -p "${VPN_PREP}"
# Copy Easy-Rsa3 directly into a setup folder
# Cannot use "*" within quotes, because inside quotes, special chars do not expand
cp -rf $HOME/easy-rsa/easyrsa3/* $VPN_PREP
cd "${VPN_PREP}"
# Can't find a use for vars because you can't control cert output paths, only pki path
#mv vars.example vars

do_purge='yes'
if [ -s "${VPN_PREP}/pki/ca.crt" ]; then
    read -n 1 -p "${YELLOW}[+] PKI Structure already exists. Purge and start fresh?${RESET} [y,N]: " response
    echo -e ""
    case $response in
        [Yy]* ) break;;
        [Nn]* ) do_purge='no';;
        * ) echo "Please answer Y or N";;
    esac
fi

if [ $do_purge == 'yes' ]; then
    # Clean
    echo -e "${GREEN}[*]${RESET} Initializing a new PKI system within the specified directory path."
    ./easyrsa init-pki
    # New PKI Dir: /root/easy-rsa/easyrsa3/pki

    # Build CA
    ./easyrsa build-ca
    # CA Cert now at: /root/easy-rsa/easyrsa3/pki/ca.crt
fi
# Build Server Key, if doesn't already exist
if [ ! -s "${VPN_PREP}/pki/private/server.key" ]; then
    echo -e "${GREEN}[*]${RESET} Generating Server Key"
    ./easyrsa gen-req server nopass
    # Result:
        #Keypair and certificate request completed. Your files are:
        #req: /root/easy-rsa/easyrsa3/pki/reqs/server.req
        #key: /root/easy-rsa/easyrsa3/pki/private/server.key

    # Sign Server Key with CA
    echo -e "${GREEN}[*]${RESET} Sign the Server Key"
    ./easyrsa sign-req server server
    #Certificate created at: /root/easy-rsa/easyrsa3/pki/issued/server.crt
fi

# Build Client Key
if [ ! -s "${VPN_PREP}/pki/private/${CLIENT_NAME}.key" ]; then
    echo -e "${GREEN}[*]${RESET} Generating Client Certificate"
    ./easyrsa gen-req "${CLIENT_NAME}" nopass
    # No password on agents, or we have to come up with a complex solution for
    # entering the password, see: https://bbs.archlinux.org/viewtopic.php?id=150440
    # Result:
    #   Keypair and certificate request completed. Your files are:
    #   req: /root/easy-rsa/easyrsa3/pki/reqs/client1.req
    #   key: /root/easy-rsa/easyrsa3/pki/private/client1.key
else
    echo -e "${RED}[-] ERROR:${RESET} This client (${CLIENT_NAME}) already has an issued key pair."
    echo -e "${RED}[-]${RESET} To make a new request, you must first revoke the original with: easyrsa3 revoke <name>."
    echo -e "${YELLOW}[*]${RESET} Proceeding with OpenVPN Server setup process."
fi

# Build Server DH Key
if [ ! -s "${VPN_PREP}/dhparam.pem" ]; then
    echo -e "${GREEN}[*]${RESET} Generating Diffie Hellman Key"
    openssl dhparam -out dhparam.pem 4096
    #openssl dhparam -out dhparam.pem 2048
fi

# Build Static HMAC Key that prevents certain DoS attacks
if [ ! -s "${VPN_PREP}/ta.key" ]; then
    echo -e "${GREEN}[*]${RESET} Generating HMAC Key"
    /usr/sbin/openvpn --genkey --secret ta.key
fi

# Generate the server configuration file
file="/etc/openvpn/server.conf"
cat <<EOF > "${file}"
daemon
dev tap
port $VPN_PORT
# TCP is more reliable than UDP if behind a proxy
proto tcp
tls-server
# --Certs--
# HMAC Protection, Server is 0, Client is 1
tls-auth ta.key 0
ca ca.crt
cert server.crt
key server.key
dh dhparam.pem
# VPN Subnet to use; Gateway being 10.8.0.1
server 10.9.8.0 255.255.255.0

# Maintain a record of IP associations. If a client goes down
# it will reconnect and be given the same IP address
ifconfig-pool-persist ipp.txt

# Redirect clients' default gateway, bypassing dhcp server issues
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"

# Push Routes to Client

# Client-specific configs or certificates
#client-config-dir ccd

# Compression, copy to client config also
comp-lzo

# This must be copied to the client config as well
cipher AES-256-CBC
keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun
# Output a short status file showing current connections, each minute
status openvpn-status.log

log-append /var/log/openvpn.log
verb 4
mute 20
# *UNTESTED* --TLS CIPHERS-- (Avoid DES)
# Below are TLS 1.2 & require OpenVPN 2.3.3+
#tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
# Below are TLS 1.0 & require OpenVPN 2.3.2 or lower
#tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA
EOF

# Generate client-specific "CCD" configs
#[[ ! -d "/etc/openvpn/ccd" ]] && mkdir -p /etc/openvpn/ccd
#file="/etc/openvpn/ccd/${CLIENT_NAME}"
#cat <<EOF > "${file}"
# This file ensures the client-specific settings
# The file's name must equal the Common Name of its certificate
# First, we give the client a set IP that never changes
#ifconfig-push 10.9.8.1 10.9.8.2

# If we want, we can enable backend routes on the client
# To enable this, you first place "route 192.158.1.0 255.255.255.0"
# into the server.conf, then uncomment the line below. 
# This will give that subnet access to the VPN. Only works if routing, 
# not bridging...e.g. using "dev tun" and "server" directives.
#iroute 192.168.1.0 255.255.255.0
#EOF


# -----------------------[ BUILD CLIENT OVPN FILE - merge.sh ]----------------------------- #
echo -e "${GREEN}[*]${RESET} Building Client conf/ovpn File"
ca="${VPN_PREP}/pki/ca.crt"
cert="${VPN_PREP}/pki/issued/${CLIENT_NAME}.crt"
key="${VPN_PREP}/pki/private/${CLIENT_NAME}.key"
tlsauth="${VPN_PREP}/ta.key"

# Generate client base config
cd "${VPN_PREP}"
file="${CLIENT_NAME}.conf"
cat << EOF > "${file}"
client
dev tap
proto tcp
# remote server IP
remote $VPN_SERVER $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
verb 3
mute 20
EOF

#	Delete pre-existing entries to keys and certs first
    sed -i \
    -e '/ca .*'$ca'/d'  \
    -e '/cert .*'$cert'/d' \
    -e '/key .*'$key'/d' \
    -e '/tls-auth .*'$tlsauth'/d' $file

#	Add keys and certs inline
echo "key-direction 1" >> $file

echo "<ca>" >> $file
awk /BEGIN/,/END/ < $ca >> $file
echo "</ca>" >> $file

echo "<cert>" >> $file
awk /BEGIN/,/END/ < $cert >> $file
echo "</cert>" >> $file

echo "<key>" >> $file
awk /BEGIN/,/END/ < $key >> $file
echo "</key>" >> $file

echo "<tls-auth>" >> $file
awk /BEGIN/,/END/ < $tlsauth >> $file
echo "</tls-auth>" >> $file


# Copy all server keys to /etc/openvpn/
echo -e "${GREEN}[*]${RESET} Moving Server Certificate Files to /etc/openvpn/"
cp -rf ./{dhparam.pem,ta.key} /etc/openvpn/
cp -rf pki/ca.crt /etc/openvpn/
cp -rf pki/private/server.key /etc/openvpn/
cp -rf pki/issued/server.crt /etc/openvpn/


# Make sure all cert/key files are set to 644
cd /etc/openvpn
chmod 644 ./{ca.crt,server.crt,server.key,ta.key,dhparam.pem}

# Enable IP Forwarding
echo -e "${GREEN}[*]${RESET} Configuring IP Forwarding and Firewall Exceptions"
echo 1 > /proc/sys/net/ipv4/ip_forward
# Make it permanent
file="/etc/sysctl.conf"
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' "${file}"

# Base Firewall Configuration to ensure success
#iptables -A FORWARD -i eth0 -o tap0 -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A FORWARD -s "{$VPN_SUBNET}/24" -o eth0 -j ACCEPT
# Only enable the line below if you wish client traffic to have Internet access
# This may be insecure if the client is in a sensitive area that shouldn't have this.
#iptables -t nat -A POSTROUTING -s "${VPN_SUBNET}/24" -o eth0 -j MASQUERADE


# Finish
cd ~
echo -e "${GREEN}[*]${RESET} Restarting OpenVPN Service to Initialize VPN Server"
service openvpn restart
sleep 5
# Ensure Apache is bound to port 443 (ssl)
netstat -nutlap | grep 443
# Disable SSL anytime with command: a2dismod ssl; service apache2 restart

echo -e "\n${GREEN}============================================================${RESET}"
echo -e "\tVPN SERVER:\t${VPN_SERVER}"
echo -e "\tVPN Port:\t${VPN_PORT}"
echo -e "\tClient CN:\t${CLIENT_NAME}"
echo -e "\tClient Conf:\t${VPN_PREP}/${CLIENT_NAME}.conf"
echo -e "${GREEN}============================================================${RESET}"
echo -e "\t\t${GREEN}[*]${RESET} OpenVPN Setup Complete!"
