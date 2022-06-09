" Enable cool stuff.
set nocompatible

" Syntax and highlighting options.
if has("syntax")
	" Enable syntax highlighting.
	syntax on

	" Highlight trailing spaces.
	match ErrorMsg '\s\+$'
endif

" Bright colours!
set background=dark

" Set a nicer color scheme (if it is present) and make set the background to black.
silent! colorscheme desert
hi Normal ctermbg=Black

" Enable better backspace.
set backspace=2

" TABs are 4 spaces.
set tabstop=4
set shiftwidth=4
set shiftround
set softtabstop=4
set copyindent

" Make <TAB> and <BS> work properly in spaces mode.
set smarttab

" Disable bell.
set vb
set t_vb=

" Ignore case when searching, unless the pattern contains an uppercase character.
set ignorecase
set smartcase

" Highlight search matches.
set hlsearch

" Always use UTF-8.
set enc=utf-8
set fenc=utf-8

" By default use UNIX line ending.
set fileformat=unix

" Better handling of multiple buffers.
set hidden

" Show line numbers.
set number

" Don't create backup and swap files.
set nobackup
set noswapfile

" Show commands as they're being typed.
set showcmd

" Bash-style tab completion
set wildmenu
set wildmode=longest,list
set wildignore=*.o,*~,*.pyc

" Handle accidental shifting of commands.
if has("user_commands")
	command W w
	command Wq wq
	command WQ wq
	command Q q
endif

" Navigate as expected on wrapped lines.
nnoremap <silent> k gk
nnoremap <silent> j gj
inoremap <silent> <Up> <Esc>gka
inoremap <silent> <Down> <Esc>gja

" Clear last search highlighting when space is pressed.
map <Space> :noh<CR>

" Automatically quit when the last buffer is closed.
function! CloseBuffer()
	if len(filter(range(1,bufnr('$')), 'buflisted(v:val)==1')) < 2 | exe ":q" | else | exe ":bdelete" | endif
endfunction
map \\ :call CloseBuffer()<CR>

" Make it easier to work with multiple buffers.
map <S-Right> :bnext<CR>
map <S-Left> :bprevious<CR>

" Display the cursor at the left of a TAB.
set list lcs=tab:\ \ 

" Add a few extra tweaks if possible.
if has("autocmd")
	" Detect tabs or spaces. Adapted from http://www.outflux.net/blog/archives/2007/03/09/detecting-space-vs-tab-indentation-type-in-vim/
	autocmd BufReadPost * if len(filter(getbufline(winbufnr(0), 1, "$"), 'v:val =~ "^ "')) > len(filter(getbufline(winbufnr(0), 1, "$"), 'v:val =~ "^\\t"')) | set expandtab | endif
endif
