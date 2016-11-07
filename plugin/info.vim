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
  autocmd BufReadCmd info://* call <SID>parseInfoURI(expand('<amatch>'))
augroup END


" Extract topic and node from URI and pass them on.
function! s:parseInfoURI(uri)
	let l:host = ''
	let l:path = ''
	let l:fragment = ''
	let l:parts = split(matchstr(a:uri, '\v^info\:\/\/\zs.*'), '/')

	if len(l:parts) > 0
		let l:host = s:percentDecode(l:parts[0])
	endif

	if len(l:parts) > 1
		let l:path = split(l:parts[1], '#')
		if len(l:path) > 1
			let l:fragment = s:percentDecode(l:path[1])
		endif
		let l:path = s:percentDecode(l:path[0])
	endif

	call info#read(l:host, l:path, l:fragment)
endfunction

function s:percentDecode(string)
	" Important: Decode the percent symbol last
	let l:string = a:string
	let l:string = substitute(l:string, '\v\%20', ' ', 'g')
	let l:string = substitute(l:string, '\v\%21', '!', 'g')
	let l:string = substitute(l:string, '\v\%23', '#', 'g')
	let l:string = substitute(l:string, '\v\%24', '$', 'g')
	let l:string = substitute(l:string, '\v\%26', '&', 'g')
	let l:string = substitute(l:string, '\v\%27', "'", 'g')
	let l:string = substitute(l:string, '\v\%28', '(', 'g')
	let l:string = substitute(l:string, '\v\%29', ')', 'g')
	let l:string = substitute(l:string, '\v\%2a', '*', 'g')
	let l:string = substitute(l:string, '\v\%2b', '+', 'g')
	let l:string = substitute(l:string, '\v\%2c', ',', 'g')
	let l:string = substitute(l:string, '\v\%2f', '/', 'g')
	let l:string = substitute(l:string, '\v\%3a', ':', 'g')
	let l:string = substitute(l:string, '\v\%3b', ';', 'g')
	let l:string = substitute(l:string, '\v\%3d', '=', 'g')
	let l:string = substitute(l:string, '\v\%3f', '?', 'g')
	let l:string = substitute(l:string, '\v\%40', '@', 'g')
	let l:string = substitute(l:string, '\v\%5b', '[', 'g')
	let l:string = substitute(l:string, '\v\%5d', ']', 'g')
	let l:string = substitute(l:string, '\v\%25', '%', 'g')

	return l:string
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
