#!/bin/bash
## ========================================================================== ##
# Build Focus:      Minimal ISO with auto-install & reverse VPN Agent
#
# Desktop:          xfce
# Metapackages:     metasploit,nmap,openvpn
# ISO Size:         885 MB
# Special Notes:    Default login is root/toor
#
# Look & Feel:
#
# DebianLive Project:   http://live.debian.net/manual
#
## ========================================================================== ##
__version__="0.1"
__author__='Cashiuus'
SCRIPT_DIR=$(dirname $0)
## ===============[ Text Colors ]================ ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## ========================================================================== ##
if [[ -s "${SCRIPT_DIR}/common.sh" ]]; then
    source "${SCRIPT_DIR}/common.sh"
else
    echo -e "${RED} [-] ERROR: ${RESET} common.sh functions file is missing."
    exit 1
fi
# ============[ DECLARE DEFAULTS ]============== #
BUILD_NAME="3-kali-reverse-vpn-persistent"
BUILD_VARIANT="variant-light"
BUILD_ARCH="amd64"
BUILD_DIST="kali-rolling"
## ========================================================================== ##

init_project

# ==================[ Recipe-Specific Customization ]==================== #
# Additional Tools/Pkgs
cd "${BUILD_DIR}"
file="${BUILD_DIR}/kali-config/${BUILD_VARIANT}/package-lists/kali.list.chroot"
grep -q "amap" "${file}" || echo -e "amap" >> "${file}"
grep -q "arp-scan" "${file}" || echo -e "arp-scan" >> "${file}"
grep -q "openvpn" "${file}" || echo -e "openvpn" >> "${file}"


## === [ SSH - Add public key to build ] === ##
setup_ssh

# === [ OpenVPN ] === ##
setup_vpn


# ======================[ Stage 2: Hooks ]=========================
# Hook 01: Auto-Start Services on boot
#file="config/hooks"
cd "${BUILD_DIR}"
filedir="kali-config/common/hooks"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
cat << EOF > "${filedir}/0501-start-services.hook.chroot"
#!/bin/bash
update-rc.d -f openvpn enable
update-rc.d -f ssh enable
EOF
chmod +x "${filedir}/0501-start-services.hook.chroot"


# ======================[ Stage 3: Includes ]=========================
# Includes: IPTables Reminder Script
cd "${BUILD_DIR}"
filedir="kali-config/common/includes.chroot/root/Desktop"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
cat << EOF > "${filedir}/setup-pivot.sh"
#!/bin/bash

echo -e "IP Forwarding has been enabled..."
echo 1 >/proc/sys/net/ipv4/ip_forward
echo -e ""
echo -e "Enter the iptables command below, replacing IP Range with VPN Range"
echo -e "\tiptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE"
echo -e ""
echo -e "Enter the route command below, replacing IP Range with Target Network Range & VPN gateway"
echo -e "\troute add -net 192.168.101.0/24 gw 10.9.8.2"

EOF
chmod +x "${filedir}/setup-pivot.sh"



# Binary 01: Override default manu, disabling the BELL sound (^G)
cd "${BUILD_DIR}"
filedir="config/includes.binary/isolinux"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
cat << EOF > "${filedir}/menu.cfg"
menu hshift 0
menu width 82

menu title Kali Linux 2.x Boot menu
include live.cfg
include install.cfg
include stdmenu.cfg
menu end

menu clear
EOF

# Override installer, setting "install" as the default choice
# This whole section is part of what turns a live ISO into a Persistent ISO
PERSISTENCE="install"
#PERSISTENCE="live"
filedir="config/includes.binary/isolinux"
[[ ! -d "${filedir}" ]] && mkdir -p "${filedir}"
cat << EOF > "${filedir}/install.cfg"
label install
    menu label ^Unattended Install Kali Linux 2016
    menu default
    linux /install/vmlinuz
    initrd /install/initrd.gz
    append vga=788 auto=true priority=critical -- locale=en_US keymap=us hostname=kali-agent domain=home file=/cdrom/install/preseed.cfg
EOF


# Binary 03: Override isolinux
cd "${BUILD_DIR}"
file="config/includes.binary/isolinux"
[[ ! -d "${file}" ]] && mkdir -p "${file}"
cat << EOF > "${file}/isolinux.cfg"
include menu.cfg
ui vesamenu.c32
default ${PERSISTENCE}
prompt 0
timeout 5
EOF


# Binary 04: Preseed File
# debian-installer - file ends up in ISO under '/cdrom/install/preseed.cfg'
# includes.installer - file ends up in ISO root '/'
cd "${BUILD_DIR}"
[[ ! -d "${BUILD_DIR}/config/includes.installer" ]] && mkdir -p "${BUILD_DIR}/config/includes.installer"
[[ ! -d "${BUILD_DIR}/config/debian-installer" ]] && mkdir -p "${BUILD_DIR}/config/debian-installer"
file2="${BUILD_DIR}/config/includes.installer/preseed.cfg"
file="${BUILD_DIR}/config/debian-installer/preseed.cfg"
#file="${BUILD_DIR}/kali-config/common/includes.installer/preseed.cfg"
cat << EOF > "${file}"
# Example Preseed: https://www.debian.org/releases/stable/example-preseed.txt
# Locale by itself sets language, country, and locale
d-i debian-installer/locale string en_US

# Or you can set them individually if needed
#d-i debian-installer/language string en
#d-i debian-installer/country string NL
#d-i debian-installer/locale string en_GB.UTF-8

### Keyboard Selection
d-i console-keymaps-at/keymap select us
d-i keyboard-configuration/xkb-keymap select us

### Network Configuration
# Uncomment next line to disable network for offline installs
# where network questions, long timeouts, and warnings are a nuisance
#d-i netcfg/enable boolean false

# netcfg will choose an interface that has link if possible. This makes it
# skip displaying a list if there is more than one interface.
d-i netcfg/choose_interface select auto
d-i netcfg/dhcp_timeout string 60

# If you prefer to configure the network manually, uncomment this line and
# the static network configuration below.
#d-i netcfg/disable_autoconfig boolean true

# If you want the preconfiguration file to work on systems both with and
# without a dhcp server, uncomment these lines and the static network
# configuration below.
#d-i netcfg/dhcp_failed note
#d-i netcfg/dhcp_options select Configure network manually

### Static network configuration.
# IPv4 example
#d-i netcfg/get_ipaddress string 192.168.1.42
#d-i netcfg/get_netmask string 255.255.255.0
#d-i netcfg/get_gateway string 192.168.1.1
#d-i netcfg/get_nameservers string 192.168.1.1
#d-i netcfg/confirm_static boolean true
#
# IPv6 example
#d-i netcfg/get_ipaddress string fc00::2
#d-i netcfg/get_netmask string ffff:ffff:ffff:ffff::
#d-i netcfg/get_gateway string fc00::1
#d-i netcfg/get_nameservers string fc00::1
#d-i netcfg/confirm_static boolean true

# Any hostname and domain names assigned from dhcp take precedence over
# values set here. However, setting the values still prevents the questions
# from being shown, even if values come from dhcp.
d-i netcfg/get_hostname string kali-agent
d-i netcfg/get_domain string local.lan

# If you want to force a hostname, regardless of what the DHCP server returns
d-i netcfg/hostname string kali-agent

### Network console
# Use the following settings if you wish to make use of the network-console
# component for remote installation over SSH. This only makes sense if you
# intend to perform the remainder of the installation manually.
#d-i anna/choose_modules string network-console
#d-i network-console/authorized_keys_url string http://10.0.0.1/openssh-key
#d-i network-console/password password sshPassword123
#d-i network-console/password-again password sshPassword123

### Apt Setup
#
### Mirror Settings
# -- Reference: http://http.kali.org/README.mirrorlist --#
d-i apt-setup/use_mirror boolean false
#d-i mirror/country string United States
# Disabled codename, d-i figures it out automatically
#d-i mirror/codename string kali
#d-i mirror/http/hostname string http.kali.org
#d-i mirror/http/directory string /sana
#d-i mirror/http/proxy string
#d-i mirror/suite string kali
#d-i apt-setup/security_host string security.kali.org/kali-security

# Disable volatile (defaults are: security, updates)
#d-i apt-setup/services-select multiselect security

# Enable contrib and non-free
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true

# Disable CDROM entries after install
d-i apt-setup/disable-cdrom-entries boolean true

# Install a limited subset of tools from the Kali Linux repositories
#d-i pkgsel/include string openssh-server openvpn metasploit-framework metasploit nano ntp

# Upgrade installed packages
# Choices: none, safe-upgrade, full-upgrade
d-i pkgsel/upgrade select safe-upgrade

# Report back installed pkgs for popularity rankings
popularity-contest popularity-contest/participate boolean false

### User Accounts
#
# Do not create a normal user account
d-i passwd/make-user boolean false
d-i passwd/root-password password ${SYS_PASSWD}
d-i passwd/root-password-again password ${SYS_PASSWD}
# or encrypted using an MD5 hash (mkpasswd -m sha-512 -or- mkpasswd -m md5)
#d-i passwd/root-password-crypted password $1$/i0jcKec$AdXAbEcIaj4g5wezvXaHL1

# The user account will be added to some standard initial groups; This overrides that.
#d-i passwd/user-default-groups string audio cdrom video

### Clock and time zone setup
#
# Controls whether or not the hardware clock is set to UTC
d-i clock-setup/utc boolean true
# Any valid TZ -- See /usr/share/zoneinfo/ for valid values
d-i time/zone string US/Eastern

# Controls whether to use NTP to set the clock during the install
#d-i clock-setup/ntp boolean true
# NTP server to use. The default is almost always fine here.
#d-i clock-setup/ntp-server string ntp.example.com

### Partitioning
#
# Will auto-select disk, but to declare specific disk use line below
#d-i partman-auto/disk string /dev/sda

# Methods:      'regular': usual partition types
#               'lvm': use LVM to partition the disk
#               'crypto': use LVN withn an encrypted partition
d-i partman-auto/method string regular
# Below are settings if an old LVM config is previously present
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

# Recipes:      'atomic': All files in one partition
#               'home': Separate /home partition
#               'multi': Separate /home, /var, /tmp partitions
d-i partman-auto/choose_recipe select atomic

# Accept Partition Selections
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

### Base system installation
#

### Boot Loader Installation
#
# Tell Grub to install automatically to MBR if no other OS detected
d-i grub-installer/only_debian boolean true
# Set to false means only install to MBR if another OS is not detected
#d-i grub-installer/with_other_os boolean false
d-i grub-installer/bootdev string /dev/sda

# Avoid final note indicating install is complete
d-i finish-install/reboot_in_progress note

# This is how to make the installer shutdown when finished, but not
# reboot into the installed system.
#d-i debian-installer/exit/halt boolean true
# This will power off the machine instead of just halting it.
#d-i debian-installer/exit/poweroff boolean true

### Preseeding other packages
#
# Depending on what software you choose to install, or if things go wrong
# during the installation process, it's possible that other questions may
# be asked. You can preseed those too, of course. To get a list of every
# possible question that could be asked during an install, do an
# installation, and then run these commands:
#   debconf-get-selections --installer > file
#   debconf-get-selections >> file

### Kismet
kismet kismet/install-setuid boolean false
kismet kismet/install-users string

### MySQL Server
mysql-server-5.5 mysql-server/root_password_again admin765
mysql-server-5.5 mysql-server/root_password admin765
mysql-server-5.5 mysql-server/error_setting_password error
mysql-server-5.5 mysql-server-5.5/postrm_remove_databases boolean false
mysql-server-5.5 mysql-server-5.5/start_on_boot boolean true
mysql-server-5.5 mysql-server-5.5/nis_warning note
mysql-server-5.5 mysql-server-5.5/really_downgrade boolean false
mysql-server-5.5 mysql-server/password_mismatch error
mysql-server-5.5 mysql-server/no_upgrade_when_using_ndb error

#### Advanced options
### Running custom commands during the installation

# This command is run as early as possible, just after preseeding is read.
#d-i preseed/early_command string anna-install some-udeb
# This command is run just before the install finishes, but when there is
# still a usable /target directory. You can chroot to /target and use it
# directly, or use the apt-install and in-target commands to easily install
# packages and run commands in the target system.
#d-i preseed/late_command string apt-install zsh; in-target chsh -s /bin/zsh
EOF
cp "${file}" "${file2}"

# =========================[ END OF CUSTOMIZATIONS ]========================== #

# ======================[ Start Build - Go get coffee ]======================= #
# Optionally, add metadata to the image
#lb config --iso-application Kali --iso-preparer Cashiuus

start_build

# =========================[ Post-Build - Move ISO ]========================== #

build_completion

