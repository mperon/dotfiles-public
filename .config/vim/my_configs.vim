" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" enable syntax
filetype plugin indent on
syntax on

" my custom color schema
" colorscheme monokai
colorscheme molokai

" enable line number by default
set number

" highlight current line
set cursorline

" visual autocomplete for command menu
set wildmenu

" redraw only when we need to.
set lazyredraw

" highlight matching [{()}]
set showmatch

set modelines=1


"change viminfo location
set viminfo+='1000,n~/.cache/.viminfo

" on git commit to to first line and insert
au! VimEnter COMMIT_EDITMSG exec 'norm gg' | startinsert!