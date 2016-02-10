#!/bin/bash
## ========================================================================== ##
set -e
set -o pipefail  # Bashism

# Supported options are:
# -d | --distribution <distro>
# -p | --proposed-updates
# -a | --arch <architecture>
#      --subdir <directory-name>
#      --version <version>
#      --variant <variant>
# -v | --verbose
# -s | --salt
BUILD_OPTS_SHORT="d:pa:vs"
BUILD_OPTS_LONG="distribution:,proposed-updates,arch:,subdir:,version:,variant:,verbose,salt"
# ============[ DECLARE DEFAULTS ]============== #
KALI_DIST="kali-current"
KALI_VERSION=""
KALI_VARIANT="default"
TARGET_DIR="$(dirname $0)/images"
TARGET_SUBDIR=""
SUDO="sudo"
VERBOSE=""
HOST_ARCH=$(dpkg --print-architecture)
## ========================================================================== ##

function image_name() {
    local arch=$1

    case "$arch" in
        i386|amd64)
            IMAGE_TEMPLATE="live-image-ARCH.hybrid.iso"
        ;;
        armel|armhf)
            IMAGE_TEMPLATE="live-image-ARCH.img"
        ;;
    esac
    echo $IMAGE_TEMPLATE | sed -e "s/ARCH/$arch/"
}

function target_image_name() {
    local arch=$1

    IMAGE_NAME="$(image_name $arch)"
    IMAGE_EXT="${IMAGE_NAME##*.}"
    if [ "$IMAGE_EXT" = "$IMAGE_NAME" ]; then
        IMAGE_EXT="img"
    fi
    if [ "$KALI_VARIANT" = "default" ]; then
        echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}kali-linux-$KALI_VERSION-$KALI_ARCH.$IMAGE_EXT"
    else
        echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}kali-linux-$KALI_VARIANT-$KALI_VERSION-$KALI_ARCH.$IMAGE_EXT"
    fi
}

function target_build_log() {
    TARGET_IMAGE_NAME=$(target_image_name $1)
    echo ${TARGET_IMAGE_NAME%.*}.log
}

function default_version() {
    case "$1" in
        kali-*)
        echo "${1#kali-}"
        ;;
        kali)
        echo "daily"
        ;;
        *)
        echo "$1"
        ;;
    esac
}

function failure() {
    # Cleanup update-kali-menu that might stay around so that the
    # build chroot can be properly unmounted
    $SUDO pkill -f update-kali-menu || true
    echo "Build of $KALI_DIST/$KALI_VARIANT/$KALI_ARCH live image failed (see build.log for details)" >&2
    exit 2
}

function run_and_log() {
    if [ -n "$VERBOSE" ]; then
        "$@" 2>&1 | tee -a build.log
    else
        "$@" >>build.log 2>&1
    fi
    return $?
}

## ==============================[ MAIN ]==================================== ##
# Parsing command line options
temp=$(getopt -o "$BUILD_OPTS_SHORT" -l "$BUILD_OPTS_LONG,get-image-path" -- "$@")
eval set -- "$temp"
while true; do
    case "$1" in
        -d|--distribution) KALI_DIST="$2"; shift 2; ;;
        -p|--proposed-updates) OPT_pu="1"; shift 1; ;;
        -a|--arch) KALI_ARCHES="${KALI_ARCHES:+$KALI_ARCHES } $2"; shift 2; ;;
        -v|--verbose) VERBOSE="1"; shift 1; ;;
        -s|--salt) shift; ;;
        --variant) KALI_VARIANT="$2"; shift 2; ;;
        --version) KALI_VERSION="$2"; shift 2; ;;
        --subdir) TARGET_SUBDIR="$2"; shift 2; ;;
        --get-image-path) ACTION="get-image-path"; shift 1; ;;
        --) shift; break; ;;
        *) echo "ERROR: Invalid command-line option: $1" >&2; exit 1; ;;
        esac
done

# Set default values
KALI_ARCHES=${KALI_ARCHES:-$HOST_ARCH}
if [ -z "$KALI_VERSION" ]; then
    KALI_VERSION="$(default_version $KALI_DIST)"
fi

# Check parameters
for arch in $KALI_ARCHES; do
    if [ "$arch" = "$HOST_ARCH" ]; then
        continue
    fi
    case "$HOST_ARCH/$arch" in
        amd64/i386|i386/amd64)
        ;;
        *)
            echo "Can't build $arch image on $HOST_ARCH system." >&2
            exit 1
        ;;
    esac
done
if [ ! -d "$(dirname $0)/kali-config/variant-$KALI_VARIANT" ]; then
    echo "ERROR: Unknown variant of Kali configuration: $KALI_VARIANT" >&2
fi

# Build parameters for lb config
KALI_CONFIG_OPTS="--distribution $KALI_DIST -- --variant $KALI_VARIANT"
if [ -n "$OPT_pu" ]; then
    KALI_CONFIG_OPTS="$KALI_CONFIG_OPTS --proposed-updates"
    KALI_DIST="$KALI_DIST+pu"
fi

# Set sane PATH (cron seems to lack /sbin/ dirs)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


function check_depends() {
    # Ensure we have proper version installed
    ver_live_build=$(dpkg-query -f '${Version}' -W live-build)
    if dpkg --compare-versions "$ver_live_build" lt 1:20151215kali1; then
        if [[ ! $checked ]]; then
            echo "ERROR: You need live-build (>= 1:20151215kali1), you have $ver_live_build" >&2
            # Use variable to ensure this only occurs once, avoiding a death loop
            checked=1
            apt-get -y install live-build && check_depends
        fi
        #exit 1
    fi
    if ! echo "$ver_live_build" | grep -q kali; then
        echo "ERROR: You need a Kali patched live-build. Your current version: $ver_live_build" >&2
        exit 1
    fi

    # Check we have a good debootstrap
    ver_debootstrap=$(dpkg-query -f '${Version}' -W debootstrap)
    if ! echo "$ver_debootstrap" | grep -q kali; then
        echo "ERROR: You need a Kali patched debootstrap. Your current version: $ver_debootstrap" >&2
        exit 1
    fi
}
check_depends


# We need root rights at some point
if [ "$(whoami)" != "root" ]; then
    if ! which $SUDO >/dev/null; then
        echo "ERROR: $0 is not run as root and $SUDO is not available" >&2
        exit 1
    fi
else
    SUDO="" # We're already root
fi

if [ "$ACTION" = "get-image-path" ]; then
    for KALI_ARCH in $KALI_ARCHES; do
        echo $(target_image_name $KALI_ARCH)
    done
    exit 0
fi



function start_build() {
    cd $(dirname $0)
    mkdir -p $TARGET_DIR/$TARGET_SUBDIR
    for KALI_ARCH in $KALI_ARCHES; do
        IMAGE_NAME="$(image_name $KALI_ARCH)"
        set +e
        : > build.log
        run_and_log $SUDO lb clean --purge
        [ $? -eq 0 ] || failure
        run_and_log lb config -a $KALI_ARCH $KALI_CONFIG_OPTS "$@"
        [ $? -eq 0 ] || failure
        run_and_log $SUDO lb build
        if [ $? -ne 0 ] || [ ! -e $IMAGE_NAME ]; then
            failure
        fi
        set -e
        mv -f $IMAGE_NAME $TARGET_DIR/$(target_image_name $KALI_ARCH)
        mv -f build.log $TARGET_DIR/$(target_build_log $KALI_ARCH)
    done
}

start_build

