#!/bin/bash
## =============================================================================
# File:     setup-gnome.sh
#
# Author:   Cashiuus
# Created:  11/27/2015  - Revised:  01/30/2016
#
# Purpose:  Configure GNOME settings on fresh Kali 2.x install
#
## =============================================================================
__version__="0.1"
__author__="Cashiuus"
## ========[ TEXT COLORS ]================= ##
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
RED="\033[01;31m"      # Issues/Errors
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal
## =========[ CONSTANTS ]================ ##


# =============================[      ]================================ #
# Disable idle timeout to screensaver
gsettings set org.gnome.desktop.session idle-delay 0

# ----------------- [ Disable Package Updater Notifications ] ------------------ #
if [[ $(which gnome-shell) ]]; then
    ##### Disabe notification package Updater
    echo -e "\n ${GREEN}[+]${RESET} Disabling notification ${GREEN}package updater${RESET} service"
    export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
    dconf write /org/gnome/settings-daemon/plugins/updates/active false
    dconf write /org/gnome/desktop/notifications/application/gpk-update-viewer/active false
    timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1
fi


# ------------------- [ Extensions ] ----------------------- #
mkdir -p "/usr/share/gnome-shell/extensions/"
# ===[ Extension: TaskBar ]==== #
git clone -q https://github.com/zpydr/gnome-shell-extension-taskbar.git /usr/share/gnome-shell/extensions/TaskBar@zpydr/ || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
#--- Gnome Extensions (Enable)
for EXTENSION in "alternate-tab@gnome-shell-extensions.gcampax.github.com" "TaskBar@zpydr" "Bottom_Panel@rmy.pobox.com" "Panel_Favorites@rmy.pobox.com" "Move_Clock@rmy.pobox.com"; do
  GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
  echo "${GNOME_EXTENSIONS}" | grep -q "${EXTENSION}" || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, '${EXTENSION}']"
done

for EXTENSION in "dash-to-dock@micxgx.gmail.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com"; do
  GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed "s_^.\(.*\).\$_\1_; s_, '${EXTENSION}'__")
  gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}]"
done

#--- Dock settings
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true        # Set dock to use the full height
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'RIGHT'     # Set dock to the right
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true           # Set dock always visible

#--- TaskBar (Global)
# Schema: https://github.com/zpydr/gnome-shell-extension-taskbar/blob/master/schemas/org.gnome.shell.extensions.TaskBar.gschema.xml
dconf write /org/gnome/shell/extensions/TaskBar/first-start false
dconf write /org/gnome/shell/extensions/TaskBar/bottom-panel true
dconf write /org/gnome/shell/extensions/TaskBar/display-favorites true
#dconf write /org/gnome/shell/extensions/TaskBar/hide-default-application-menu true
#dconf write /org/gnome/shell/extensions/TaskBar/display-showapps-button false
#dconf write /org/gnome/shell/extensions/TaskBar/appearance-selection "'showappsbutton'"
#dconf write /org/gnome/shell/extensions/TaskBar/overview true
dconf write /org/gnome/shell/extensions/TaskBar/position-appview-button 2
dconf write /org/gnome/shell/extensions/TaskBar/position-desktop-button 0
dconf write /org/gnome/shell/extensions/TaskBar/position-favorites 3
dconf write /org/gnome/shell/extensions/TaskBar/position-max-right 4
dconf write /org/gnome/shell/extensions/TaskBar/position-tasks 4
dconf write /org/gnome/shell/extensions/TaskBar/position-workspace-button 1
dconf write /org/gnome/shell/extensions/TaskBar/position-bottom-box 0           # 0=left, 1=center, 2=right
dconf write /org/gnome/shell/extensions/TaskBar/icon-size-bottom 26             # Default is 22, height of bottom panel
dconf write /org/gnome/shell/extensions/TaskBar/bottom-panel-original-background-color "'rgba(57,59,63,0.49647887323943662)'"
dconf write /org/gnome/shell/extensions/TaskBar/separator-two true
dconf write /org/gnome/shell/extensions/TaskBar/separator-three true
dconf write /org/gnome/shell/extensions/TaskBar/separator-four true
dconf write /org/gnome/shell/extensions/TaskBar/separator-five true
#dconf write /org/gnome/shell/extensions/TaskBar/separator-six true
#dconf write /org/gnome/shell/extensions/TaskBar/separator-three-bottom true
#dconf write /org/gnome/shell/extensions/TaskBar/separator-five-bottom true
dconf write /org/gnome/shell/extensions/TaskBar/appview-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/appview-button-default.svg'"
dconf write /org/gnome/shell/extensions/TaskBar/desktop-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/desktop-button-default.png'"
dconf write /org/gnome/shell/extensions/TaskBar/tray-button-icon "'/usr/share/gnome-shell/extensions/TaskBar@zpydr/images/bottom-panel-tray-button.svg'"


#--- Gedit
gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
gsettings set org.gnome.gedit.preferences.editor editor-font "'Monospace 10'"
gsettings set org.gnome.gedit.preferences.editor insert-spaces true
gsettings set org.gnome.gedit.preferences.editor right-margin-position 90
gsettings set org.gnome.gedit.preferences.editor tabs-size 4


#--- Workspaces
gsettings set org.gnome.shell.overrides dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
#--- Top bar
gsettings set org.gnome.desktop.interface clock-show-date true

# TODO: Modify the default "favorite apps"
gsettings set org.gnome.shell favorite-apps "['iceweasel.desktop', 'gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'kali-burpsuite.desktop', 'kali-msfconsole.desktop', 'geany.desktop']"

# Titlebar Font - Originally it is 'Cantarell Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-font "'Droid Bold 10'"
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false


#--- Disable tracker service (But enables it in XFCE)
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false



function finish {
    # Any script-termination routines go here

}
# End of script
trap finish EXIT
