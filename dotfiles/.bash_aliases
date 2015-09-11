### .bash_aliases
### by Cashiuus        (Updated: 2015-09-11)
###
### ------------------------------------------ ###
alias bashload='source $HOME/.bashrc'

### Networking
alias myip='curl ifconfig.me'
#alias myip="curl -s http://ipinfo.io/ip"
alias openports='netstat --all --numeric --programs --inet' # or netstat -tulanp
alias ping='ping -c 1'
alias webserv='python -m SimpleHTTPServer'
alias header="curl -I"
alias update-kali="apt-get update && apt-get -y upgrade"


### Application Shortcuts
alias chrome='/opt/google/chrome/chrome'
alias tmux="tmux attach || tmux new"
alias axel="axel -a"
alias screen="screen -xRR"
alias strings="strings -a"
alias nmap="nmap --reason --open"
alias aircrack-ng="aircrack-ng -z"
alias airodump-ng="airodump-ng --manufacturer --wps --uptime"

### Metasploit
alias msfc="systemctl start postgresql; msfdb start; msfconsole -q \"$@\""
alias msfconsole="systemctl start postgresql; msfdb start; msfconsole -q \"$@\""

alias openvas="openvas-stop; openvas-start; sleep 3s; xdg-open https://127.0.0.1:9392/ >/dev/null 2>&1"
alias mana-toolkit-start="a2ensite 000-mana-toolkit;a2dissite 000-default;systemctl apache2 restart"
alias mana-toolkit-stop="a2dissite 000-mana-toolkit;a2ensite 000-default;systemctl apache2 restart"


### Checksums
alias sha1="openssl sha1"
alias md5="openssl md5"

### Folder Creation
alias mkdir="/bin/mkdir -pv"

### Folder Shortcuts
alias d="cd ~/Documents"
alias dl="cd ~/Downloads"
alias drop="cd ~/drop"
alias e="cd ~/engagements"
alias g="cd /opt/git"
alias p="cd ~/projects"

alias ..="cd .."
alias ...="cd ../.."
alias cdup="cd .."

### CLI Navigation
alias more='less'

### Colorizing
alias grep="grep --color=auto -I" #ignore binary files when searching inside
alias ngrep="ngrep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto -I"

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
else # OS X `ls`
	colorflag="-G"
fi

# Always use color output for `ls`
alias ls="command ls -Ahp ${colorflag}"
# List all files colorized in long format
alias l="ls -lF ${colorflag}"
# List all files colorized in long format, including dot files
alias la="ls -laF ${colorflag}"
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'


# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
# Always print human-readable for various disk space commands
alias df='df -h'
alias free='free -h'
alias du='du -s -h'

# Setup SUDO action for non-root usage
if [ $UID -ne 0 ]; then
	alias s='sudo '
	alias scat='sudo cat'
	alias stail='sudo tail'
	alias root='sudo su'
	alias reboot='sudo reboot'
	alias halt='sudo halt'
fi

### Spelling Error Variants
alias got='git '
alias get='git '
