### For Reference:
###		.bashrc			- Executes for all non-login BASH shells 
###							(e.g. scripts with #!/bin/bash)
###		.bash_profile	- Executes for all login BASH shells
###		.profile		- Executes for all login shells, not just BASH
###		
### 

### Load the configs that affect login shells
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

### Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

### Custom Prompt
export PS1="\[\033[31m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[36m\]\w\[\033[m\]\$ "

function git-current-branch {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
}
export PS1="\$(git-current-branch)$PS1"
