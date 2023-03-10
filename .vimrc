"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.

"       Amir Salihefendic — @amix3k
"           https://github.com/amix/vimrc
set nocompatible

set runtimepath+=~/.config/vim/

" Add Plugin System
try
	source ~/.config/vim/plug.vim
catch
endtry

" Add Default VIM Settings
try
	source ~/.config/vim/basic.vim
	source ~/.config/vim/extended.vim
catch
endtry

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"try
	source ~/.config/vim/my_configs.vim
"catch
"endtry
