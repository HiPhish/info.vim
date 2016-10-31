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

function! InfoNodeFolds()
	" Folding is simple: If it's not a node header use the previous fold
	" level. If it is a node header use the length of the node's path.

	let l:thisline = getline(v:lnum)

	" Lines that aren't header nodes are always on the same level as the node
	" they belong to
	if !s:IsNodeHeader(l:thisline)
		return '='
	endif

	let l:node = matchstr(l:thisline, '\v(Node: )@<=[^,]+')

	return '>'.(len(b:nodes[l:node]['path']) - 1)
endfunction

function! s:IsNodeHeader(line)
	return !empty(matchstr(a:line, '\v^((File|Node|Next|Prev|Up)\:\s+[^,]+\,?\s*)+$'))
endfunction

" Strip the 'File: foo.info' part from the line
function! s:FoldText()
	return substitute(getline(v:foldstart), '\vFile: [^,]+\,\s*', '', '')
endfunction

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

setlocal foldmethod=expr
setlocal foldexpr=InfoNodeFolds()
let &l:foldtext = s:SID() . 'FoldText()'

" vim:tw=78:ts=4:noexpandtab:norl:
