" The tab-related settings are needed to ensure proper display because info
" files use tabs for alignment of text.
setlocal noexpandtab
setlocal tabstop=8
setlocal softtabstop=8
setlocal shiftwidth=8


command! -buffer Toc call info#toc(<q-mods>)
command! -buffer TOC :Toc

command! -buffer -nargs=? Node call info#node(<q-args>)

" vim:tw=78:ts=4:noexpandtab:norl:
