" ============================================================================
" Markdown preview in the browser, styled with a custom CSS theme.
" Requires the Vundle plugin manager (https://github.com/VundleVim/Vundle.vim)
" to already be initialised earlier in your vimrc via:
"
"   set nocompatible
"   filetype off
"   set rtp+=~/.vim/bundle/Vundle.vim
"   call vundle#begin()
"   Plugin 'VundleVim/Vundle.vim'
"   ... (this block goes inside the vundle#begin()/vundle#end() section) ...
"   call vundle#end()
"   filetype plugin indent on
" ============================================================================

" ---- MARKDOWN PREVIEW ----
Plugin 'previm/previm'                     " Markdown preview in browser
Plugin 'tyru/open-browser.vim'             " Dependency for previm: opens links/preview in default browser

" previm renders a plain, unstyled white-background page unless told otherwise.
" Disabling the default CSS and pointing at a custom stylesheet gives full
" control over the preview's look (fonts, code blocks, tables, etc).
let g:previm_disable_default_css = 1
let g:previm_custom_css_path = '~/.vim/bundle/previm-theme/nord-dark.css'

" Open the current Markdown buffer's live preview in the browser
nnoremap <leader>mp :PrevimOpen<CR>
