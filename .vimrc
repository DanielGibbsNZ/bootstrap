" Enable cool stuff.
set nocompatible

" Syntax and highlighting options.
if has("syntax")
	" Enable syntax highlighting.
	syntax on

	" Highlight trailing spaces.
	match ErrorMsg '\s\+$'
endif

" Set a nicer color scheme (if it is present).
silent! colorscheme delek

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

" Bright colours!
set background=dark

" Ignore case when searching, unless the pattern contains an uppercase character.
set ignorecase
set smartcase

" Highlight search matches.
set hlsearch

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
map N Nzz
map n nzz

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

" Show commands as they're being typed
set showcmd

" Bash-style tab completion
set wildmenu
set wildmode=longest,list

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

" Display the cursor at the left of a TAB.
set list lcs=tab:\ \ 

" Add a few extra tweaks if possible.
if has("autocmd")
	" Automatically quite after last buffer closed.
	autocmd BufDelete * if len(filter(range(1, bufnr('$')), '!empty(bufname(v:val)) && buflisted(v:val)')) == 1 | quit! | endif

	" Detect tabs or spaces. Adapted from http://www.outflux.net/blog/archives/2007/03/09/detecting-space-vs-tab-indentation-type-in-vim/
	autocmd BufReadPost * if len(filter(getbufline(winbufnr(0), 1, "$"), 'v:val =~ "^ "')) > len(filter(getbufline(winbufnr(0), 1, "$"), 'v:val =~ "^\\t"')) | set expandtab | endif
endif
