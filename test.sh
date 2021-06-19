#!/bin/bash

nvim -Nu <(cat << VIMRC
filetype off
set rtp+=$HOME/.vim/plugged/vader.vim
set rtp+=.
set rtp+=after
set maxfuncdepth=1000
filetype plugin indent on
syntax enable
VIMRC) -c "Vader! test/*" > /dev/null
