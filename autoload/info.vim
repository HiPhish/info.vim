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

" This is the program that assembles info files, we might later decide to make
" it possible to define your own one.
if !exists('g:info_compiler')
	let g:info_compiler = 'info'
endif


" The entry function, invoked by the ':Info' command. Its purpose is to find
" the topic and options from the arguments
function! info#info(mods, ...)
	if a:0 == 0
		" TODO: use the word under the cursor as the topic
		error 'Error: Need an argument.'
	endif

	let l:topic = a:1
	let l:bufname = 'info://' . l:topic

	" The following will trigger the autocommand of editing an info:// file
	if a:mods !~# 'tab' && s:find_info()
		execute 'silent edit' l:bufname
	else
		execute 'silent' a:mods 'split' l:bufname
	endif
endfunction


" This function is called by the autocommand when editing an info:// buffer.
function! info#read_doc(uri)
	" TODO: split the path of the URI at the slashes to get the topic and
	" nodes
	let l:topic = substitute(matchstr(a:uri, 'info://\zs.*'), '\v\/$', '', '')
	call s:read_topic(l:topic)
endfunction


" Here the heavy heavy lifting happens: we set the options for the buffer and
" load the info document.
function! s:read_topic(topic)
	" We will lock it after assembly
	setlocal modifiable
	setlocal noreadonly
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=hide

	" Here is where the magic happens: we use the 'info' command to assemble
	" the final info document; documents can be split over multiple files, so
	" this is an effective way of assembling them. We have to re-direct the
	" stderr to '/dev/null' because info uses it to print status messages even
	" if no error occurred.
	silent keepjumps %delete _
	let l:cmd = g:info_compiler.' '.a:topic.' 2>/dev/null'
	if &shell =~# 'fish$'
		let l:cmd = substitute(l:cmd, '\v2\>\/dev\/null$', '^/dev/null')
	endif
	put =system(l:cmd)

	" Jump to the first line and delete it because it's blank
    silent keepjumps 1delete _

	" Now lock the file and set all the remaining options
	setlocal filetype=info
	setlocal nonumber
	setlocal norelativenumber
	setlocal nomodifiable
	setlocal nomodified
	setlocal readonly
	setlocal foldcolumn=0
	setlocal colorcolumn=0
	setlocal nolist
	setlocal nospell
endfunction



" Try finding an exising 'info' window in the current tab. Returns 0 if no
" window was found.
function! s:find_info() abort
	" Try the windows in the following order:
	"   - If the current window matches use it
	"   - If there is only one window (first window is last) do not use it
	"   - Cycle through all windows until one is found
	"   - If none was found return 0
	if &filetype ==# 'info'
		return 1
	elseif winnr('$') ==# 1
		return 0
	endif
	let thiswin = winnr()
	while 1
		wincmd w
		if &filetype ==# 'info'
			return 1
		elseif thiswin ==# winnr()
			return 0
		endif
	endwhile
endfunction
