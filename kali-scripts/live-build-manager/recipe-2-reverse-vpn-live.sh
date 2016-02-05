#!/bin/bash
## ========================================================================== ##
#
# Created:
# Author:           Cashiuus - cashiuus(at)gmail(dot)com
#
# Build Focus:      Minimal ISO with auto-install & reverse VPN Agent
#
# Desktop:          xfce
# Metapackages:
# ISO Size:         885 MB
# Special Notes:    Default login is root/toor
#
# Look & Feel:
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
BUILD_NAME="2-kali-reverse-vpn-live"
BUILD_VARIANT="variant-light"
BUILD_ARCH="amd64"
BUILD_DIST="kali-rolling"
## ========================================================================== ##

init_project

# ==================[ Recipe-Specific Customization ]==================== #

## === [ SSH - Add public key to build ] === ##
setup_ssh
# === [ OpenVPN ] === ##
setup_vpn
# Copy default xfce4 layout so we don't get the first-run prompt
xfce4_default_layout


# ======================[ Stage 1: Packages ]=========================
# Additional Last-Minute Tools/Pkgs
cd "${BUILD_DIR}"
file="${BUILD_DIR}/kali-config/${BUILD_VARIANT}/package-lists/kali.list.chroot"
grep -q "amap" "${file}" || echo -e "amap" >> "${file}"
grep -q "arp-scan" "${file}" || echo -e "arp-scan" >> "${file}"
grep -q "openvpn" "${file}" || echo -e "openvpn" >> "${file}"
grep -q "sysv-rc-conf" "${file}" || echo -e "sysv-rc-conf" >> "${file}"

# ======================[ Stage 2: Hooks ]=========================
# Hook 01: Auto-Start Services on boot
#file="config/hooks"
cd "${BUILD_DIR}"
hooksdir="kali-config/common/hooks"
#filedir="config/hooks"
[[ ! -d "${hooksdir}" ]] && mkdir -p "${hooksdir}"
cat <<EOF > "${hooksdir}/01-start-services.chroot"
#!/bin/bash
service ssh start
service openvpn start
update-rc.d -f openvpn enable
update-rc.d -f ssh enable
EOF
chmod 755 "${hooksdir}/01-start-services.chroot"
# +x stopped working correctly


# ======================[ Stage 3: Includes ]=========================
# Includes: IPTables Reminder Script
cd "${BUILD_DIR}"
includesdir="kali-config/common/includes.chroot/root/Desktop"
[[ ! -d "${includesdir}" ]] && mkdir -p "${includesdir}"
cat << EOF > "${includesdir}/setup-pivot.sh"
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
chmod 755 "${includesdir}/setup-pivot.sh"


# Binary 01: Override default manu, disabling the BELL sound (^G)
cd "${BUILD_DIR}"
file="config/includes.binary/isolinux"
[[ ! -d "${file}" ]] && mkdir -p "${file}"
cat << EOF > "${file}/menu.cfg"
menu hshift 0
menu width 82

menu title Kali Linux 2.x Boot menu
include live.cfg
include install.cfg
include stdmenu.cfg
menu end

menu clear
EOF


# Binary 03: Override isolinux
cd "${BUILD_DIR}"
file="config/includes.binary/isolinux"
[[ ! -d "${file}" ]] && mkdir -p "${file}"
cat << EOF > "${file}/isolinux.cfg"
include menu.cfg
ui vesamenu.c32
default live
prompt 0
timeout 5
EOF


# =========================[ END OF CUSTOMIZATIONS ]========================== #

# ======================[ Start Build - Go get coffee ]======================= #

# Optionally, add metadata to the image
#lb config --iso-application Kali --iso-preparer Cashiuus

start_build

# =========================[ Post-Build - Move ISO ]========================== #

build_completion

