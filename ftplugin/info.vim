" The tab-related settings are needed to ensure proper display because info
" files use tabs for alignment of text.
setlocal noexpandtab
setlocal tabstop=8
setlocal softtabstop=8
setlocal shiftwidth=8


nnoremap <buffer> g? :call <SID>help()<CR>


command! -buffer Toc call info#toc(<q-mods>)
command! -buffer TOC :Toc
command! -buffer -nargs=? Node call info#node(<q-args>)


" Echo a quick instruction list
function! s:help()
	echomsg 'The following commands are defined in ''info'' buffers:'
	echomsg '  :Toc              Open table of contents in locatio list'
	echomsg '  :Node             Echo the current node'
	echomsg '  :Node <node>      Jump to node <node>'
	echomsg '  :Node -next       Jump to next node'
	echomsg '  :Node -previous   Jump to previous node'
	echomsg '  :Node -up         Jump to parent node'
	echomsg 'See '':help info.vim'' for more details.'
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
