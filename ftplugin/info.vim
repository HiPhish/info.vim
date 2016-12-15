" Author: Alejandro "HiPhish" Sanchez
" License:  The MIT License (MIT) {{{
"    Copyright (c) 2016 HiPhish
"
"    Permission is hereby granted, free of charge, to any person obtaining a
"    copy of this software and associated documentation files (the
"    "Software"), to deal in the Software without restriction, including
"    without limitation the rights to use, copy, modify, merge, publish,
"    distribute, sublicense, and/or sell copies of the Software, and to permit
"    persons to whom the Software is furnished to do so, subject to the
"    following conditions:
"
"    The above copyright notice and this permission notice shall be included
"    in all copies or substantial portions of the Software.
"
"    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
"    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
"    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
"    USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}


" The tab-related settings are needed to ensure proper display because info
" files use tabs for alignment of text.
setlocal noexpandtab
setlocal tabstop=8
setlocal softtabstop=8
setlocal shiftwidth=8


nnoremap <buffer> g? :call <SID>help()<CR>


" Echo a quick instruction list
function! s:help()
	echomsg 'Execute '':Info info.vim'' for an interactive tutorial. The following'
	echomsg 'commands are defined in ''info'' buffers:'
	echomsg '  :Menu [entry]   Jump to a menu entry or open menu in location list'
	echomsg '  :Follow [xRef]  Follow reference and cross-references'
	echomsg '  :InfoUp         Go to parent node'
	echomsg '  :InfoNext       Go to next node'
	echomsg '  :InfoPrev       Go to previous node'
	echomsg 'See '':help info.vim'' for more details and mappings.'
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
