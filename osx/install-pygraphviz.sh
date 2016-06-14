#!/usr/bin/env bash
#
# Purpose: Setup pygraphviz in order to use djang-extensions python library




#Install brew app
brew install graphviz
brew cleanup
# Activate virtualenv - python side
workon
echo "Type name of virtualenv you want to use: "
read choice
workon choice

pip install --upgrade pip

# Install py library now using custom include directory paths for the 'c' libraries
pip install pygraphviz --install-option="--include-path=/usr/local/include/graphviz/" --install-option="--library-path=/usr/local/lib/graphviz"