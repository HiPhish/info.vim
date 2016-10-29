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


if exists('g:loaded_info')
  finish
endif
let g:loaded_info = 1


command! -nargs=* Info call info#info(<q-mods>, <f-args>)


augroup info
  autocmd!
  autocmd BufReadCmd info://* call info#parseInfoURI(expand('<amatch>'))
augroup END


" Extract topic and node from URI and pass them on.
function! info#parseInfoURI(uri)
	let l:host = ''
	let l:fragment = ''
	let l:parts = split(matchstr(a:uri, '\v^info:\/\/\zs.*'), '#')

	if len(l:parts) > 0
		let l:host = l:parts[0]
	endif

	if len(l:parts) > 1
		let l:fragment = l:parts[1]
	endif
	echom l:host
	echom l:fragment

	call info#read_doc(l:host, l:fragment)
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
