#
# =============[ Default Settings ]============== #
SCRIPT_DIR=$(readlink -f $0)
APP_BASE=$(dirname ${SCRIPT_DIR})
BUILDS_BASE="${APP_BASE}/builds"
MASTER_CONFIG="${HOME}/git/master-live-build-config"


# ===========[ Functions for all Live Build Recipes ]============= #
update_kali() {
    apt-get update -qq
    # *NOTE: On 9/10/2015, Kali changed from cdebootstrap to debootstrap due to live-build 5.x
    apt-get install -y -qq git live-build debootstrap devscripts kali-archive-keyring apt-cacher-ng
}


create_conf() {
    # During first-run, create the 'mybuilds.conf' file that stores useful settings
    mkdir -p "${BUILDS_BASE}"
    cat << EOF > "${APP_BASE}/config/mybuilds.conf"
# PERSONAL BUILD SETTINGS
VPN_SERVER=''
VPN_PORT='1194'
VPN_CLIENT_CONF="${APP_BASE}/config/vpn-client-confs/client-example.conf"
ISO_FINAL_DIR="/var/www/html/iso"
EOF
    echo -e "${YELLOW} [WARN] First-Run: Settings file created at ${APP_BASE}/config/mybuilds.conf${RESET}"
    echo -e "${YELLOW} [WARN] Open file for editing and press ANY KEY when ready to continue...${RESET}"
    read
    init_project
}


init_project() {
    # If we have just pulled down this project, intialize the project directory and configurations
    if [[ -z "${APP_BASE}/config/mybuilds.conf" ]]; then
        #read -p "[+] Declare your BUILDS folder for this and future build efforts: " -i "${HOME}/builds" -e BUILDS_BASE
        create_conf
    else
        source "${APP_BASE}/config/mybuilds.conf"
    fi
    
    BUILD_DIR="${BUILDS_BASE}/${BUILD_NAME}"
    IMAGES_DIR="${BUILD_DIR}/images"

    # Establish the main config structure we begin with
    [[ ! -d "{BUILD_DIR}" ]] && mkdir -p "${BUILD_DIR}"
    if [[ ! -d "${MASTER_CONFIG}" ]]; then
        mkdir -p ~/git && cd ~/git
        git clone git://git.kali.org/live-build-config.git master-live-build-config
    fi
    
        # Copy the master config git to this project folder if it's not already there
    if [[ ! -d "{BUILD_DIR}/kali-config" ]]; then
        # Cannot use "*" within quotes, because inside quotes, special chars do not expand
        cp -r ${MASTER_CONFIG}/* ${BUILD_DIR}
    fi
    
    # -------- Setup a build cache -- to make future builds much faster
    # Launch apt-cache if not already running
    netstat -antpl | grep -q "3142" && /etc/init.d/apt-cacher-ng start && export http_proxy=http://localhost:3142/

    cd "${BUILD_DIR}"
    START_TIME=$(date +%s)
    
    echo -e "\n${BLUE}=================[  Kali 2.x Live Build Engine  ]=================${RESET}"
    echo -e "\tBuild Name:\t${BUILD_NAME}"
    echo -e "\tBuild Variant:\t${BUILD_VARIANT}"
    echo -e "\tBuild Path:\t${BUILD_DIR}"
    echo -e "${BLUE}=========================< version: ${__version__} >=========================\n${RESET}"
}


# === [ Post-Build ] === #
build_completion() {
    FINISH_TIME=$(date +%s)
    # Remove default from string, output filename only includes variant if it's not the default
    if [[ $STR_VARIANT == 'default' ]]; then
		ISO_NAME="kali-linux-${BUILD_DIST}-${BUILD_ARCH}.iso"
	else
		ISO_NAME="kali-linux-${STR_VARIANT}-${BUILD_DIST}-${BUILD_ARCH}.iso"
	fi
	ISO_FILE="${IMAGES_DIR}/${ISO_NAME}"
    echo -e "${GREEN} -- Build Completed Successfully ${YELLOW}( Time: $(( $(( FINISH_TIME - START_TIME )) / 60 )) minutes )${GREEN} --\n${RESET}"
    
    echo -e "${GREEN}[*]${RESET} Copying finished ISO to www Directory"
	#echo -e "${GREEN}Location of ISO:${RESET} ${ISO_FILE}"
    
	[[ ! -d "${ISO_FINAL_DIR}" ]] && mkdir -p "${ISO_FINAL_DIR}"
	md5sum "${ISO_FILE}" > "${ISO_FINAL_DIR}/${BUILD_NAME}.md5"
	# -u = means only copy if source file is newer than destination file
	cp -u "${ISO_FILE}" "${ISO_FINAL_DIR}/${BUILD_NAME}.iso"
}


# === [ SSH ] === #
configure_ssh() {
    #
    # SSH  -------- Create SSH key w/o password since it's for an agent
    cd "${BUILD_DIR}"
    [[ ! -s "${HOME}/.ssh/id_rsa" ]]  &&   ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -P ""
    file="config/includes.chroot/root/.ssh"
    [[ ! -d "${file}" ]] && mkdir -p "${file}"
    [[ -s "${file}/authorized_keys" ]] && rm "${file}/authorized_keys"
    cp -u "${HOME}/.ssh/id_rsa.pub" "${file}/authorized_keys"
}


install_git() {
    #TODO: Function to clone git repo
    CLONE_PATH='/opt/git'
    
    git clone -q ${1} || echo -e '[ERROR] Problem cloning ${1}'
}
