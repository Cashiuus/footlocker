#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: setup-ssh-server.sh          (Update: 10-10-2015) #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
# Usage:  Setup SSH Server on Kali Linux to non-default port  #
#          and also replacing original keys with new ones     #
#                                                             #
#                                                             #
#-------------------------------------------------------------#
# Thanks to: https://www.lisenet.com/2013/openssh-server-installation-and-configuration-on-debian/
#
SSH_SERVER_IP=192.168.1.50
SSH_SERVER_PORT=60022


apt-get -qq update
apt-get -y -qq install openssh-server openssl
update-rc.d -f ssh remove
update-rc.d -f ssh defaults

# Move the default Kali keys to backup folder
cd /etc/ssh
mkdir insecure_original_kali_keys
mv ssh_host_* insecure_original_kali_keys/

# Wipe clean any ssh keys in root profile, leaving authorized_keys file intact
[[ ! -d "${HOME}/.ssh"]] && mkdir -p "${HOME}/.ssh"
find "${HOME}/.ssh/" -type f ! -name authorized_keys -delete

# Get the currently-installed version of openssh-server
tmp=$(dpkg -s openssh-server | grep "^Version" | cut -d ":" -f3)
openssh_version="${tmp:0:3}"

function version () {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';

}

function version_check () {
    if [ $(version $1) -ge $(version $2) ]; then
        echo "$1 is newer than $2"
        return 0
    elif [ $(version $1) -lt $(version $2) ]; then
        echo "$1 is older than $2"
        return 1
    fi
}

# Call version check to test if installed version is at least 6.5 or newer (-o)
version_check $ver 6.5
if [ $? == 0 ]; then
    echo -e "[*] Newer OpenSSH Version detected, proceeding with new key format"
    ssh-keygen -b 4096 -t rsa1 -o -f /etc/ssh/ssh_host_key -P ""
    ssh-keygen -b 2048 -t rsa -o -f /etc/ssh/ssh_host_rsa_key -P ""
    ssh-keygen -b 1024 -t dsa -o -f /etc/ssh/ssh_host_dsa_key -P ""
    ssh-keygen -b 521 -t ecdsa -o -f /etc/ssh/ssh_host_ecdsa_key -P ""
else
    echo -e "[-] OpenSSH Version is older than v6.5, Proceeding with PEM key format"
    ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P ""
    ssh-keygen -b 2048 -t rsa -f /etc/ssh/ssh_host_rsa_key -P ""
    ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P ""
    ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P ""
fi
# Generate personal key pair
ssh-keygen -b 2048 -t rsa -f "${HOME}/.ssh/id_rsa" -P ""

# Protect files
chmod 0700 "${HOME}/.ssh"
chmod 0644 "${HOME}/.ssh/id_rsa.pub"
chmod 0400 "${HOME}/.ssh/id_rsa"


# Compare MD5 to ensure new key is different from original
echo -e "[*] Compare the MD5 Hashes below to ensure new key is, in fact, new!"
openssl md5 /etc/ssh/default_kali_keys/ssh_host_*
openssl md5 /etc/ssh/ssh_host_*
sleep 5

# Copy Public key to auth file; Private key goes to client
# TODO: May need to insert this at the top, and appned existing keys below it
# to avoid old key being read first if this key is replacing an existing entry
file="${HOME}/.ssh/authorized_keys"
cat "${HOME}/.ssh/id_rsa.pub" >> "${file}"
# NOTE: authorized_keys file should be set to 644
chmod 644 "${file}"

# TODO: Create a use specifically for ssh so we aren't connecting as root, can always su


# Configure the MOTD banner message remote users see, 2 versions below
# Create ASCII Art: http://patorjk.com/software/taag/
cat << EOF > /etc/motd
##########################++++++++++##########################
#        (   (      (                      )  (              #
#        )\ ))\ )   )\ )   (      *   ) ( /(  )\ )           #
#       (()/(()/(( (()/(   )\   ` )  /( )\())(()/(           #
#        /(_))(_))\ /(_)|(((_)(  ( )(_)|(_)\  /(_))          #
#       (_))(_))((_|_))_ )\ _ )\(_(_())  ((_)(_))            #
#       | _ \ _ \ __|   \(_)_\(_)_   _| / _ \| _ \           #
#       |  _/   / _|| |) |/ _ \   | |  | (_) |   /           #
#       |_| |_|_\___|___//_/ \_\  |_|   \___/|_|_\           #
#         Welcome to Predator Secure Shell Server            #
#             All Connections Are Monitored                  #
#         Do Not Probe for Vulns -- Play nice ;)             #
#                                                            #
#     DISCONNECT NOW IF YOU ARE NOT AN AUTHORIZED USER       #
##########################++++++++++##########################
EOF



cat << EOF > /etc/motd2
###########################++++++++++###########################
#             Welcome to the Secure Shell Server               #
#               All Connections are Monitored                  #
#           Do Not Probe for Vulns -- Play nice ;)             #
#                                                              #
#      DISCONNECT NOW IF YOU ARE NOT AN AUTHORIZED USER        #
###########################++++++++++###########################
EOF

# ---------------------- [ SSHD CONFIG TWEAKS ] ---------------------- #

file=/etc/ssh/sshd_config
# Find "Banner" in file and change to motd if not already
# Orig: #Banner /etc/issue.net

# *NOTE: When using '/' for paths in sed, use a different delimiter, such as # or |
sed -i 's|^[#B]anner /etc/issue\.net|Banner /etc/motd|g' $file
#sed -i 's/^Banner \/etc\/issue\.net/Banner \/etc\/motd/g' $file

# Change SSH port to non-default
file=/etc/ssh/sshd_config; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^[#P]ort.*/Port 60022/g' $file

#sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/g' "${file}"

# Host Keys
# -- All are same, but put a '#' in front of: HostKey /etc/ssh/ssh_host_ed25519_key
sed -i 's|^HostKey /etc/ssh/ssh_host_ed25519_key|#HostKey /etc/ssh/ssh_host_ed25519_key|' "${file}"

# -- Server Key Bits (Default: 1024)
sed -i -e 's|\(ServerKeyBits\) 1024|\1 2048|' "${file}"

# -- Login Grace Time (Default: 120)
sed -i 's/^LoginGraceTime.*/LoginGraceTime 60/' "${file}"

# -- Enable Public Key Logins
sed -i 's|#AuthorizedKeysFile.*|AuthorizedKeysFile	%h/.ssh/authorized_keys|' "${file}"

# -- Disable Password Logins if using Pub Key Auth
#sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "${file}"
#sed -i -e 's|\(PasswordAuthentication\) no|\1 yes|' /etc/ssh/sshd_config

# -- X11 Forwarding
#sed -i 's/X11Forwarding.*/X11Forwarding no/' >> "${file}"
sed -i 's/^X11DisplayOffset.*/X11DisplayOffset 15/' "${file}"

# -- Ciphers
grep -q '^Ciphers ' "${file}" 2>/dev/null || echo "\nCiphers aes256-ctr,aes192-ctr,aes128-ctr" >> "${file}"

# -- Add Inactivty Timeouts
#echo "\nClientAliveInterval 600\nClientAliveCountMax 3" >> "${file}"

# -- Add Whitelist and Blacklist of Users
#grep -q '^AllowUsers ' "${file}" 2>/dev/null || echo "\nAllowUsers newuser newuser2" >> "${file}"
#grep -q '^DenyUsers ' "${file}" 2>/dev/null || echo "\nDenyUsers root" >> "${file}"
#grep -q '^DenyGroups ' "${file}" 2>/dev/null || echo "\nDenyGroups root" >> "${file}"
#grep -q '^PrintLastLog ' "${file}" 2>/dev/null || echo "\nPrintLastLog yes" >> "${file}"

# ------------------------------------------------------------------- #


# IPTABLES
#iptables -A INPUT -p tcp --dport $SSH_SERVER_PORT -j ACCEPT

# Restart SSH Server
service ssh restart
update-rc.d -f ssh enable

# Connect to SSH Server
#ssh -24x -i "${HOME}/.ssh/my_key" root@$SSH_SERVER_IP -p $SSH_SERVER_PORT

# Check for any Invalid User Login Attempts
#cat /var/log/auth.log | grep "Invalid user" | cut -d " " -f 1-3,6-11 | uniq | sort