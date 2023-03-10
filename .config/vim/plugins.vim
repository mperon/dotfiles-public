" ========================================
" Vim plugin configuration
" ========================================
"
" Check the status using command:
"		 :PlugStatus
"
" And type following command and hit ENTER to install the plugins that you have 
" declared in the config file earlier.
" 		:PlugInstall
"
" Update Plugins
" 
" To update plugins, run:
" 		:PlugUpdate

" Installling
if empty(glob('~/.config/vim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/vim/autoload/plug.vim --create-dirs \
  	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"starting
call plug#begin('~/.cache/vim/bundle')

try
	"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	" => My Custom Plugins
	"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	"Plug 'vim-airline/vim-airline'
	"Plug 'klen/python-mode'

	"if has('mac')
	""  Plug 'junegunn/vim-xmark'
	"endif
catch
endtry

" Automatically install missing plugins on startup
if !empty(filter(copy(g:plugs), '!isdirectory(v:val.dir)'))
  autocmd VimEnter * PlugInstall | q
endif

" end of plugins
call plug#end()




