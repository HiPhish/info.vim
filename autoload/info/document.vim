" Author: Alejandro "HiPhish" Sanchez
" License:  The MIT License (MIT) {{{
"    Copyright (c) 2016-2018 HiPhish
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


" This file contains exposed functions for document-wide actions.
" Document-wide means the scope is beyond the current node, but within the
" current file. It does not mean that the functions operate on the entire
" document or between documents.


function! info#document#next()
	let l:current_file = b:info.File
	let l:menu_entries = copy(get(b:info, 'Menu', []))
	call filter(l:menu_entries, {_,v->v['File'] =~# l:current_file})
	if !empty(l:menu_entries)
		return l:menu_entries[0]
	endif
	unlet l:menu_entries

	" if has_key(b:info, 'Next') && b:info.Next.File =~# l:current_file
	" 	return b:info.Next.File
	" endif

	echoerr 'No more nodes within this document'
endfunction

function! info#document#prev()
	let l:current_file = b:info.File

	for l:direction in ['Prev', 'Up']
		if has_key(b:info, l:direction) && b:info[l:direction].File =~# l:current_file
			return b:info[l:direction].File
		endif
	endfor

	echoerr 'No ''Prev'' or ''Up'' for this node within this document'
endfunction
