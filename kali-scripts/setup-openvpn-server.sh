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
#        Uses the newer easy-rsa3 version to generate         #
#        the certificate package.                             #
#        Lastly, we merge all client certs into a             #
#        singular file.                                       #
#                                                             #
#-------------------------------------------------------------#
# OpenVPN Hardening Cheat Sheet: http://darizotas.blogspot.com/2014/04/openvpn-hardening-cheat-sheet.html
#

# ----- EDIT VARIABLES ----- #
VPN_PREP_DIR="${HOME}/vpn-setup"
VPN_SERVER='cashiuus-predator.ddns.net'
VPN_PORT='443'
CLIENT_NAME="client-public"
VPN_SUBNET="10.9.8.0"
# -------------------------- #

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

# ====================================================================================== #
# ------------------------------------[ Begin Script ]---------------------------------- #
sudo apt-get install openvpn openssl -y
service openvpn stop
openvpn --version

if [[ ! -d "$HOME/easy-rsa" ]]; then
	git clone git://github.com/OpenVPN/easy-rsa
fi

[[ ! -d "${VPN_PREP_DIR}" ]] && mkdir -p "${VPN_PREP_DIR}"
# Copy Easy-Rsa3 directly into a setup folder
# Cannot use "*" within quotes, because inside quotes, special chars do not expand
cp -u ${HOME}/easy-rsa/easyrsa3/* ${VPN_PREP_DIR}
cd "${VPN_PREP_DIR}"
# NOTE: Can't find a use for vars because you can't control cert output paths, only pki path
#mv vars.example vars

DO_PURGE='yes'
if [[ -s "${VPN_PREP_DIR}/pki/ca.crt" ]]; then
    echo -e "\n${YELLOW}[*] PKI Structure already exists!${RESET}"
    read -n 1 -p " [+] Purge PKI and start fresh? [y,N]: " -e response
    echo -e ""
    case $response in
        [Yy]* ) break;;
        [Nn]* ) DO_PURGE='no';;
        * ) DO_PURGE='no';;
    esac
fi

if [[ ${DO_PURGE} == 'yes' ]]; then
    # Clean
    echo -e "${GREEN}[*]${RESET} Initializing a new PKI system within the specified directory path."
    ./easyrsa init-pki
    # Result:
        # New PKI Dir: ${VPN_PREP_DIR}/pki

    # Build CA
    ./easyrsa build-ca
    # Result:
        # CA Cert now at: ${VPN_PREP_DIR}/pki/ca.crt
fi

# Build Server Key, if it doesn't already exist
if [[ ! -s "${VPN_PREP_DIR}/pki/private/server.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating Server Key"
    ./easyrsa gen-req server nopass
    # Result:
    #   Keypair and certificate request completed. Your files are:
    #   request:    ${VPN_PREP_DIR}/pki/reqs/server.req
    #   key:        ${VPN_PREP_DIR}/pki/private/server.key

    # Sign Server Key with CA
    echo -e "${GREEN}[*]${RESET} Sign Server Certificate; Enter CA Passphrase below"
    ./easyrsa sign-req server server
    # Result:
    #   Certificate created at: ${VPN_PREP_DIR}/pki/issued/server.crt
    cp -u pki/private/server.key /etc/openvpn/
    cp -u pki/issued/server.crt /etc/openvpn/
fi

# Build Server DH Key
if [[ ! -f "${VPN_PREP_DIR}/dhparam.pem" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating Diffie Hellman Key"
    openssl dhparam -out dhparam.pem 4096
    #openssl dhparam -out dhparam.pem 2048
fi

# Build Static HMAC Key that prevents certain DoS attacks
if [[ ! -f "${VPN_PREP_DIR}/ta.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating HMAC Key"
    /usr/sbin/openvpn --genkey --secret ta.key
fi

# Build Client Key, if it doesn't already exist (*Noticing a trend?!?)
if [[ ! -f "${VPN_PREP_DIR}/pki/private/${CLIENT_NAME}.key" ]]; then
    echo -e "${GREEN}[*]${RESET} Generating Client Certificate"
    ./easyrsa gen-req "${CLIENT_NAME}" nopass
    sleep 3
    echo -e "${GREEN}[*]${RESET} Sign Client Certificate; Enter CA Passphrase below"
    ./easyrsa sign-req client "${CLIENT_NAME}"
    # No password on agents, or we have to come up with a complex solution for
    # entering the password, see: https://bbs.archlinux.org/viewtopic.php?id=150440
    # Result:
    #   Keypair and certificate request completed. Your files are:
    #   request:    /root/easy-rsa/easyrsa3/pki/reqs/client1.req
    #   key:        /root/easy-rsa/easyrsa3/pki/private/client1.key
    # -----------------------[ BUILD CLIENT OVPN FILE - merge.sh ]----------------------------- #
    echo -e "${GREEN}[*]${RESET} Building Client conf/ovpn File"
    ca="${VPN_PREP_DIR}/pki/ca.crt"
    cert="${VPN_PREP_DIR}/pki/issued/${CLIENT_NAME}.crt"
    key="${VPN_PREP_DIR}/pki/private/${CLIENT_NAME}.key"
    tlsauth="${VPN_PREP_DIR}/ta.key"

    # Generate client base config
    cd "${VPN_PREP_DIR}"
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
else
    echo -e "${RED}[-] ERROR:${RESET} This client (${CLIENT_NAME}) already has an issued key pair."
    echo -e "${RED}[-]${RESET} To make a new request, you must first revoke the original with: ./easyrsa revoke <name>. Then, you may also need to manually delete this client's \".crt, .key, and .req\" files."
    echo -e "${YELLOW}[*]${RESET} Proceeding with OpenVPN Server setup process."
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
# VPN Subnet to use; Gateway being 10.9.8.1
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

# Cipher entries must be copied to the client config as well
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
# This will give that subnet access to the VPN and vice versa. Only works if routing, 
# not bridging...e.g. using "dev tun" and "server" directives.
#iroute 192.168.1.0 255.255.255.0
#EOF


# Copy all server keys to /etc/openvpn/ if they've been updated
echo -e "${GREEN}[*]${RESET} Moving Server Certificate Files to /etc/openvpn/"
cp -u ./{dhparam.pem,ta.key} /etc/openvpn/
cp -u pki/ca.crt /etc/openvpn/


# Make sure all cert/key files are set to 644
chmod 644 /etc/openvpn/{ca.crt,server.crt,server.key,ta.key,dhparam.pem}

# Enable IP Forwarding
echo -e "${GREEN}[*]${RESET} Configuring IP Forwarding and Firewall Exceptions"
echo 1 > /proc/sys/net/ipv4/ip_forward
# Make it permanent
file="/etc/sysctl.conf"
sed -i 's|^#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' "${file}"

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
# Ensure Apache is not bound to port 443 (ssl) or server cannot bind to port 443
# NOTE: Disable SSL anytime with command: a2dismod ssl; service apache2 restart
netstat -nutlap | grep 443


echo -e "\n${YELLOW}[+] Enable OpenVPN for Autostart${RESET}"
read -n 1 -p " [+] Enable OpenVPN for Autostart?${RESET} [Y,n]: " -i "y" -e response
echo -e ""
case $response in
    [Yy]* ) ENABLE='yes';;
    [Nn]* ) ENABLE='no';;
    * ) echo "Please answer Y or N";;
esac
[[ ${ENABLE} == 'yes' ]] && systemctl enable openvpn


echo -e "\n${GREEN}============================================================${RESET}"
echo -e "\tVPN SERVER:\t${VPN_SERVER}"
echo -e "\tVPN Port:\t${VPN_PORT}"
echo -e "\tClient CN:\t${CLIENT_NAME}"
echo -e "\tClient Conf:\t${VPN_PREP_DIR}/${CLIENT_NAME}.conf"
echo -e "${GREEN}============================================================${RESET}"
echo -e "\t\t${GREEN}[*]${RESET} OpenVPN Setup Complete!"
