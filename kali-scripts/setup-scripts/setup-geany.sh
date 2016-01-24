#!/bin/bash
# ==============================================================================
# File:     setup-geany.sh
# Author:   cashiuus@gmail.com
# Created:  10/10/2015
# Revised:  
#
# Purpose:  Configure Geany settings on fresh Kali 2.x install
#
# ==============================================================================
__version__="0.1"

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


# ------------ DECLARE CONSTANTS -------------
BACKUPS_DIR="$HOME/Backups/geany"



apt-get install -y -qq geany python-pip
pip install flake8 pep8-naming

if [[ $(which gnome-shell) ]]; then
    dconf load /org/gnome/gnome-panel/layout/objects/geany/ << EOF
[instance-config]
location='/usr/share/applications/geany.desktop'

[/]
object-iid='PanelInternalFactory::Launcher'
pack-index=3
pack-type='start'
toplevel-id='top-panel'
EOF

    dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'geany']/")"
fi


#--- Configure geany
timeout 5 geany >/dev/null 2>&1

file=/root/.config/geany/geany.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
touch ${file}  # *** this will not work as geany now only writes its config after a 'clean' quit.
sed -i 's/^.*editor_font=.*/editor_font=Monospace\ 9/' "${file}"
sed -i 's/^.*sidebar_pos=.*/sidebar_pos=1/' "${file}"
#sed -i 's/^.*check_detect_indent=.*/check_detect_indent=true/' "${file}"       # I'd rather make all files use spaces
sed -i 's/^.*detect_indent_width=.*/detect_indent_width=true/' "${file}"
sed -i 's/^.*pref_editor_tab_width=.*/pref_editor_tab_width=4/' "${file}"       # Python encourages width: 4
sed -i 's/^.*indent_type.*/indent_type=2/' "${file}"
sed -i 's/^.*autocomplete_doc_words=.*/autocomplete_doc_words=true/' "${file}"
sed -i 's/^.*completion_drops_rest_of_word=.*/completion_drops_rest_of_word=true/' "${file}"
sed -i 's/^.*tab_order_beside=.*/tab_order_beside=true/' "${file}"
sed -i 's/^.*show_indent_guide=.*/show_indent_guide=true/' "${file}"
sed -i 's/^.*long_line_column=.*/long_line_column=90/' "${file}"                # Originally 72, g0tmi1k uses 48
sed -i 's/^.*line_wrapping=.*/line_wrapping=true/' "${file}"
sed -i 's/^.*pref_editor_newline_strip=.*/pref_editor_newline_strip=true/' "${file}"
sed -i 's/^.*pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' "${file}"
sed -i 's/^.*pref_editor_replace_tabs=.*/pref_editor_replace_tabs=true/' "${file}"
sed -i 's/^.*pref_editor_trail_space=.*/pref_editor_trail_space=true/' "${file}"
sed -i 's/^.*pref_toolbar_append_to_menu=.*/pref_toolbar_append_to_menu=true/' "${file}"
sed -i 's/^.*pref_toolbar_use_gtk_default_style=.*/pref_toolbar_use_gtk_default_style=false/' "${file}"
sed -i 's/^.*pref_toolbar_use_gtk_default_icon=.*/pref_toolbar_use_gtk_default_icon=false/' "${file}"
sed -i 's/^.*pref_toolbar_icon_size=/pref_toolbar_icon_size=2/' "${file}"
sed -i 's/^.*treeview_position=.*/treeview_position=744/' "${file}"
sed -i 's/^.*msgwindow_position=.*/msgwindow_position=405/' "${file}"
sed -i 's/^.*pref_search_hide_find_dialog=.*/pref_search_hide_find_dialog=true/' "${file}"
sed -i 's#^.*project_file_path=.*#project_file_path=/root/#' "${file}"
grep -q '^custom_commands=sort;' "${file}" || sed -i 's/\[geany\]/[geany]\ncustom_commands=sort;/' "${file}"

# Tools
# Defaults:
#   [tools]
#   terminal_cmd=x-terminal-emulator -e "/bin/sh %c"
#   browser_cmd=sensible-browser
#   grep_cmd=grep


# Build Commands
# File-dependent build commands go in their own file for each filetype
file="$HOME/.config/geany/filedefs"
[[ -d "${file}" ]] && mkdir -p "${file}"
cat << EOF > "${file}/filetypes.python"
[build-menu]
FT_01_LB=Check
FT_01_CM=flake8 --show-source "%f"
FT_01_WD=
error_regex=([^:]+):([0-9]+):([0-9:]+)? .*
FT_00_LB=Py_Compile
FT_00_CM=python -m py_compile "%f"
FT_00_WD=
EOF

# Add custom config for flake8 checking, exclude noisy Error Codes
file="$HOME/.config/flake8"
cat << EOF > "${file}"
# E***/W*** Codes are PEP8, F*** codes are PyFlakes, 
# N8** codes are pep8-naming, C9** are McCabe complexity plugin
# See: http://pep8.readthedocs.org/en/latest/intro.html#error-codes
[flake8]
ignore = F403,E265
# E265 -    block comment should start with a '# '
# F403 -    from module import *’ used; unable to detect undefined names
max-line-length = 90
exclude = tests/*,.git,__pycache
EOF

# Add other files to filetype coloring config
file="$HOME/.config/geany/filetype_extensions.conf"
[[ ! -s "${file}" ]] && cp "/usr/share/geany/filetype_extensions.conf" "${file}"
sed -i 's/^C=\*\.c;\*\.h.*;/C=*.c;*.h;*.nasl;/' "${file}"
sed -i 's/^Sh=\*\.sh;configure;.*/Sh=*.sh;configure;configure.in;configure.in.in;configure.ac;*.ksh;*.mksh;*.zsh;*.ash;*.bash;*.m4;PKGBUILD;*profile;*.bash*;/' "${file}"


# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' "${file}"
mkdir -p "${BACKUPS_DIR}"
mkdir -p /root/.config/geany/plugins/saveactions/
file=/root/.config/geany/plugins/saveactions/saveactions.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
[saveactions]
enable_autosave=false
enable_instantsave=false
enable_backupcopy=true

[autosave]
print_messages=false
save_all=false
interval=300

[instantsave]
default_ft=None

[backupcopy]
dir_levels=5
time_fmt=%Y-%m-%d-%H-%M-%S
backup_dir=$BACKUPS_DIR
EOF

