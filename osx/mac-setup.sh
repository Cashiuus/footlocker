#!/usr/bin/env bash
# ==============================================================================
# File:     setup-mac.sh
#
# Author:   Cashiuus
# Created:  09-JUN-2016     -     Revised: 16-DEC-2016
#
#-[ Usage ]---------------------------------------------------------------------
#   1. Modify constants in script below
#   2. Run script and enjoy
#
#
#-[ Notes/Links ]---------------------------------------------------------------
#
#
#-[ References ]----------------------------------------------------------------
#   - Another option-Vagrant VMs: http://joebergantine.com/projects/django/django-newproj/
#   - Tut: https://hackercodex.com/guide/mac-osx-mavericks-10.9-configuration/
#
#-[ Copyright ]-----------------------------------------------------------------
#   MIT License ~ http://opensource.org/licenses/MIT
# ==============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]=============== ##
# [https://wiki.archlinux.org/index.php/Color_Bash_Prompt]
# [https://en.wikipedia.org/wiki/ANSI_escape_code]
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
PURPLE="\033[01;35m"   # Other
ORANGE="\033[38;5;208m" # Debugging
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##
START_TIME=$(date +%s)
APP_PATH=$(readlink -f $0)
APP_BASE=$(dirname "${APP_PATH}")
APP_NAME=$(basename "${APP_PATH}")
DEBUG=false

# ==================================[ ]========================================= #

# Initiate sudo before we get started
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ==================================[ ]========================================= #
# Manually open the AppStore and download "XCode" first
# Then in Terminal, run xcode-select --install
echo "XCode already installed? If not, cancel script and install via AppStore first."
read
xcode-select --install
sudo xcodebuild -license


# ---- Setup Homebrew ----
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew doctor

# Add brew to PATH
grep -q '^PATH=/usr/local/bin:/usr/local/sbin:$PATH' ~/.bash_profile 2>/dev/null \
    || echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
source ~/.bash_profile


# -----[ Setup Python 2 Core ]-----
# Tut: http://docs.python-guide.org/en/latest/starting/install/osx/
# Tut: https://hackercodex.com/guide/python-development-environment-on-mac-osx/
# Tut: http://joebergantine.com/blog/2015/apr/30/installing-python-2-and-python-3-alongside-each-ot/
# Tut: http://protips.maxmasnick.com/installing-python-3-alongside-python-2-on-os-x-yosemite

py2='2.7'
brew install python
# Optional: You can run 'brew linkapps python' to symlink these to /Applications

pip install django
pip install requests
pip install virtualenv
pip install virtualenvwrapper


#pip install http://downloads.sourceforge.net/project/mysql-python/....

# Setup virtualenv config for creating a Python 2 environment
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python2
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv-2.7
source /usr/local/bin/virtualenvwrapper.sh

# Make a default primary directory for all virtual env's
#mkdir -p ~/virtualenvs

# Can add this so pip only runs if a virtualenv is active
#file=~/.bashrc
#echo 'export PIP_REQURE_VIRTUALENV=true' >> "${file}"
#source ~/.bash_profile   <-- assuming this file auto-sources .bashrc

# Then, you would want to define a function for a way of
# still being able to pip install something globally when necessary
# add this to ~/.bashrc
# pip-global(){
    #PIP_REQUIRE_VIRTUALENV="" pip "$@"
#}
# and save

# Create default virtualenv
mkvirtualenv py27

# install pip packages here

# Back to global
deactivate

# Setup a default django env
mkvirtualenv py27-Django
workon py27-Django
pip install django
pip install psycopg2
pip install pygraphviz
deactivate


# ----[ Python 3 ]------
py3='3.5'
brew install python3
# You can run 'brew linkapps python3' to symlink these to /Applications
# This will install to /usr/local/lib/python3.5/ as well as pip installs
# You can run 'pip3 install <package>'
pip3 install --upgrade pip
pip3 install virtualenv
pip3 install virtualenvwrapper

# Setup for Python 3
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv-3.5
source /usr/local/bin/virtualenvwrapper.sh

mkvirtualenv py35
# or just do mkvirtualenv -p python3 env-3.5
workon py35
# Install pip packages here

# Deactivate this virtualenv in prep for the next one
deactivate


# Now go in and create a 'postactivate' script inside this folder
cd env
echo 'proj_name=${VIRTUAL_ENV##*/}' > ~/virtualenvs/env/postactivate
echo '# Add the active project to the PYTHONPATH' >> ~/virtualenvs/env/postactivate
echo 'if [ -d ~/sites/env/$proj_name/lib/python2.7/site-packages ]; then' >> ~/virtualenvs/env/postactivate
echo '  add2virtualenv ~/sites/env/$proj_name/lib/python2.7/site-packages' >> ~/virtualenvs/env/postactivate
echo 'fi' >> ~/virtualenvs/env/postactivate
echo '# "cd" into the virtualenv, or its "project" folder if there is one' >> ~/virtualenvs/env/postactivate
echo 'if [ -d ~/sites/env/$proj_name/project ]; then' >> ~/virtualenvs/env/postactivate
echo '  cd ~/sites/env/$proj_name/project' >> ~/virtualenvs/env/postactivate
echo 'else' >> ~/virtualenvs/env/postactivate
echo '  cd ~/sites/env/$proj_name' >> ~/virtualenvs/env/postactivate
echo 'fi' >> ~/virtualenvs/env/postactivate

# Reload shell
source ~/.bash_profile

# Activate the default env
workon py27

# ----- VNC Viewer ----- *BROKEN*
#echo '#!/usr/bin/env bash' >> /usr/local/bin/vncviewer
#echo 'open vnc://\$1' >> /usr/local/bin/vncviewer
#chmod +x /usr/local/bin/vncviewer


# ----- Setup Nginx -----
# https://gist.github.com/epicserve/311159

# ----- Setup Apache & PHP -----
# https://gist.github.com/epicserve/311159


# ----- Setup Oh-My-ZSH -----
#echo "Installing Oh-My-ZSH, please wait..."
#curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
