" Author: Alejandro "HiPhish" Sanchez
" License:  The MIT License (MIT) {{{
"    Copyright (c) 2016-2019 HiPhish
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


" Parse a reference string into a reference object.
function! info#reference#decode(string, context)
	" Strip away the leading cruft first: '* ' and '*Note '
	let l:reference = matchstr(a:string, '\v^\*([Nn]ote\s+)?\s*\zs.+')
	" Try the '* Note::' type of reference first
	let l:name = matchstr(l:reference, '\v^\zs[^:]+\ze\:\:')

	if empty(l:name)
		" The format is '* Name: (file)Node.*
		let [l:name, l:node] = split(l:reference, '\v\:\s')

		let l:file = matchstr(l:node, '\v^\s*\(\zs[^)]+\ze\)')
		" If there is no file the current one is implied
		if empty(l:file)
			let l:file = a:context['File']
		endif

		let l:node = matchstr(l:node, '\v^\s*(\([^)]+\))?\zs[^.,[:tab:]]+')
	else
		let l:node = l:name
		let l:file = a:context['File']
	endif

	return {'Name': l:name, 'File': l:file, 'Node': l:node}
endfunction
