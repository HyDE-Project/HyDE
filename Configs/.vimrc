let mapleader = " "

syntax on "parser

filetype plugin indent on


colorscheme zaibatsu "the only nice built-in colorscheme 

set number
set relativenumber

" nvim defaults
set tabstop=4        
set shiftwidth=4     
set expandtab        

set hlsearch "hilight search, :nohl to remove

set t_Co=256 "terminal colors

set wildmenu " auto completion, trigger with <C-n> 

"remaps
inoremap <C-c> <Esc>
nnoremap <leader>ff :w<CR>
nnoremap ; :
vnoremap ; :
