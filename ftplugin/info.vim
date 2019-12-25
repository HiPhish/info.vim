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
setlocal noexpandtab tabstop=8 softtabstop=8 shiftwidth=8

" Settings inside this condition only apply rendered Info files, not on-disc
" Info files.
if &buftype =~? 'nofile'
	nnoremap <buffer> g? :call <SID>help()<CR>
	setlocal bufhidden=hide
	setlocal noswapfile nonumber nomodified nolist nospell
	setlocal foldcolumn=0 colorcolumn=0
	setlocal concealcursor="nc" conceallevel=2
endif

let s:help_message =
	\"Execute ':Info info.vim' for an interactive tutorial. The following\n"
	\.."commands are defined in 'info' buffers:\n"
	\.."  :Menu [entry]   Jump to a menu entry or open menu in location list\n"
	\.."  :Follow [xRef]  Follow reference and cross-references\n"
	\.."  :InfoUp         Go to parent node\n"
	\.."  :InfoNext       Go to next node\n"
	\.."  :InfoPrev       Go to previous node\n"
	\.."See ':help info.vim' for more details and mappings."

" Echo a quick instruction list
function! s:help()
	echo s:help_message
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
