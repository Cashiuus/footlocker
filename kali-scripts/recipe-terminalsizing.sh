#!/bin/bash

# Recipe:
#   Determine terminal size and use that to
#   adjust output of certain output elements


# This works just fine in Kali's default terminal, xterm
TERMINAL_WIDTH=$(stty size | cut -d " " -f2)
# If the above doesn't work, try this version instead
#TERMINAL_WIDTH=$(ps aux | cut -c1-$(stty size </dev/tty | cut -d " " -f2)

echo "Variable: ${TERMINAL_WIDTH}"

### Function to take a symbol and terminal width to output a string of equal length
generator()
{
    printf "$1"'%.s' $(eval "echo {1.."$(($2))"}");
    #printf "$1"'%.s' {1..${2}}
}



MY_SYMBOL='#'*${TERMINAL_WIDTH}
echo
generator '*' ${TERMINAL_WIDTH}
#echo -e "${MY_LINE}"
echo

# Some shells (zsh) will actually store width in a variable $COLUMNS, but kali default does not


echo " ------- If you would like to make output like \"ps aux\""
echo "      conform to terminal width, use this"
echo "      ps aux | cut -c1-\$(stty size </dev/tty | cut -d \" \" -f2)"
echo

AUTO_WIDTH=$(ps aux | cut -c1-$(stty size </dev/tty | cut -d " " -f2))
#echo "Result: ${AUTO_WIDTH}"
