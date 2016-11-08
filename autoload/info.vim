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
if !exists('g:infoprg')
	let g:infoprg = 'info'
endif

" Public interface functions {{{1

" The entry function, invoked by the ':Info' command. Its purpose is to find
" the file and options from the arguments
function! info#info(mods, ...)
	let l:file = ''
	let l:node = ''

	if a:0 > 0
		let l:file = a:1
	endif

	if a:0 > 1
		let l:node = a:2
	endif

	let l:bufname = s:encodeURI(l:file, l:node, '')

	" The following will trigger the autocommand of editing an info:// file
	if a:mods !~# 'tab' && s:find_info_window()
		execute 'silent edit' l:bufname
	else
		execute 'silent' a:mods 'split' l:bufname
	endif

	echo 'Welcome to Info. Type g? for help.'
endfunction


" Access the menu in a node.
function! info#menu(entry)
	if a:entry == ''
		call s:menuLocationList()
		lopen
		return
	endif

	call s:buildMenu()
	for l:entry in b:info['Menu']
		if l:entry['Description'] =~? a:entry
			let l:uri = s:encodeURI(l:entry['File'], l:entry['Node'], '')
			let l:uri = substitute(l:uri, '\v\%', '\\%', 'g')

			execute 'silent edit '.l:uri
			return
		endif
	endfor

	echohl ErrorMsg
	echo 'Cannot find menu entry ' . a:entry
	echohl None
endfunction


" This function is called by the autocommand when editing an info:// buffer.
function! info#read(file, node, line)
	let l:file = a:file
	let l:node = a:node

	if empty(l:file)
		let l:file = 'dir'
	endif
	if empty(l:node)
		let l:node = 'Top'
	endif

	call s:readInfo(l:file, l:node)

	" Jump to the given line
	if !empty(a:line)
		execute 'normal! '.a:line.'G'
	endif
endfunction

" Jump to the next node
function! info#next()
	call s:jumpToProperty('Next')
endfunction

" Jump to the next node
function! info#prev()
	call s:jumpToProperty('Prev')
endfunction

" Jump to the next node
function! info#up()
	call s:jumpToProperty('Up')
endfunction


" Completion function {{{1

" Filter the menu list for entries which match non-magic, case-insensitive and
" only at the beginning of the string.
function! info#completeMenu(ArgLead, CmdLine, CursorPos)
	call s:buildMenu()
	let l:menu = b:info['Menu']
	let l:candidates = []

	for l:entry in l:menu
		" Match only at the beginning of the string
		if empty(a:ArgLead) || !empty(matchstr(l:entry['Description'], '\c\M^'.a:ArgLead))
			call add(l:candidates, l:entry['Description'])
		endif
	endfor

	return l:candidates
endfunction


" Private functions for reading info documents {{{1

" Here the heavy heavy lifting happens: we set the options for the buffer and
" load the info document.
function! s:readInfo(file, node, ...)
	" We will lock it after assembly
	setlocal modifiable
	setlocal readonly
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=hide

	" TODO: We first have to check if file and node even exist
	silent keepjumps %delete _

	" Make sure to redirect the standard error into the void and quote the
	" name of the file and node (they may contain spaces and parentheses).
	let l:cmd = g:infoprg.' -f '''.a:file.''' -n '''.a:node.''' -o - 2>/dev/null'
	" And adjust the redirection syntax for special snowflake shells
	if &shell =~# 'fish$'
		let l:cmd = substitute(l:cmd, '\v2\>\/dev\/null$', '^/dev/null')
	endif

	put =system(l:cmd)
	" Putting has produced an empty line at the top, remove that
    silent keepjumps 1delete _

    normal! gg

	" Now lock the file and set all the remaining options
	setlocal filetype=info
	setlocal nonumber
	setlocal norelativenumber
	setlocal nomodifiable
	setlocal nomodified
	setlocal foldcolumn=0
	setlocal colorcolumn=0
	setlocal nolist
	setlocal nospell

	let b:info = s:parseNodeHeader()
endfunction


" Parses the information from the node header and returns a dictionary
" representing it.
function! s:parseNodeHeader()
	let l:info = {}

	" We assume that the header is the first line. Split the header into
	" key-value pairs.
	let l:pairs = split(getline(1), ',')

	for l:pair in l:pairs
		" A key is terminated by a colon and might have leading whitespace.
		let l:key = matchstr(l:pair, '\v^\s*\zs[^:]+')
		" The value might have leading whitespace as well
		let l:value = matchstr(l:pair, '\v^\s*[^:]+\:\s*\zs[^,]+')
		let l:info[l:key] = l:value
	endfor

	return l:info
endfunction


" Common code for next, previous, and so on nodes
function! s:jumpToProperty(property)
	if exists('b:info['''.a:property.''']')
		" The node name might contain a file name: (file)Node
		let l:file = matchstr(b:info[a:property], '\v^\(\zs[^)]+\ze\)')
		if empty(file)
			let l:file = b:info['File']
		endif

		let l:uri = s:encodeURI(l:file, b:info[a:property], '')
		" We have to escape the percent signs or it will be replaced with the
		" file name in the ':edit'
		let l:uri = substitute(l:uri, '\v\%', '\\%', 'g')

		execute 'silent edit '.l:uri
	else
		echohl ErrorMsg | echo 'No '''.a:property.''' pointer for this node.' | echohl None
	endif
endfunction


" Try finding an exising 'info' window in the current tab. Returns 0 if no
" window was found.
function! s:find_info_window() abort
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


" Private functions for menus {{{1

" Build up a list of menu entries in a node.
function! s:buildMenu()
	" This function will be called lazily when we need a menu. Don't rebuild
	" it is one already exists.
	if exists('b:info[''Menu'']')
		return
	endif

	let l:save_cursor = getcurpos()
	let b:info['Menu'] = []
	let l:menuLine = search('\v^\* [Mm]enu\:')

	if l:menuLine == 0
		return
	endif

	" Process entries by searching down from the menu line. Don't wrap to the
	" beginning of the file or we will be stuck in an infinite loop.
	let l:entryLine = search('\v^\*[^:]+\:', 'W')
	while l:entryLine != 0
		call add(b:info['Menu'], s:decodeReference(getline(l:entryLine)))
		let l:entryLine = search('\v^\*[^:]+\:', 'W')
	endwhile

	call setpos('.', l:save_cursor)
endfunction

" Populate location list with menu items.
function s:menuLocationList()
	call s:buildMenu()
	call setloclist(0, [], ' ', 'Menu')

	for l:item in b:info['Menu']
		let l:uri = s:encodeURI(l:item['File'], l:item['Node'], '')
		laddexpr l:uri.'\|1\| '.l:item['Description']
	endfor
endfunction

" Parse a reference string into a reference object.
function! s:decodeReference(line)
	" Strip away the leading cruft first: '* ' and '*Note '
	let l:reference = matchstr(a:line, '\v^\*([Nn]ote\s+)?\s*\zs.+')
	" Try the '* Node::' type of reference first
	let l:title = matchstr(l:reference, '\v^\s*\zs[^:]+\ze\:\:')

	if empty(l:title)
		" The format is '* Title: (file)Node.*
		let l:title = matchstr(l:reference, '\v^\s*\zs[^:]+\ze\:')
		let l:file = matchstr(l:reference, '\v^[^)]+\(\zs[^)]+\ze\)')
		" If there is no file the current one is implied
		if empty(file)
			let l:file = b:info['File']
		endif
		let l:node = matchstr(l:reference, '\v^[^:]+\:\s*(\(.+\))?\zs[^.]+\ze\.')
	else
		let l:node = l:title
		let l:file = b:info['File']
	endif

	return {'Description': l:title, 'File': l:file, 'Node': l:node}
endfunction

" Private functions for searching {{{1

function! s:search()
	let s:string = ''
	if exists('b:info[''Search'']')
		let s:string = b:info['Search']
	endif
	let l:string = input('Search for string: ', l:string)

	if empty(s:string)
		return
	endif
	let b:info['Search'] = l:string
	unlet l:string

	let l:file = b:info['file']
	let l:node = b:info['node']
	let l:line = line('.')

	while search(b:info['Search'], 'W') == 0
		if !exists('b:info[''Next'']')
		endif
	endwhile
endfunction
" URI-handling function {{{1

function! s:encodeURI(file, node, line)
	let l:file = s:percentEncode(a:file)
	let l:node = s:percentEncode(a:node)
	let l:line = s:percentEncode(a:line)

	let l:uri = 'info://'
	if !empty(l:file)
		let l:uri .= l:file.'/'
		if !empty(l:node)
			let l:uri .= l:node.'/'
		endif
	endif

	return l:uri
endfunction

function! s:percentEncode(string)
	" Important: Encode the percent symbol first
	let l:string = a:string
	let l:string = substitute(l:string, '\v\%', '%25', 'g')
	let l:string = substitute(l:string, '\v\ ', '%20', 'g')
	let l:string = substitute(l:string, '\v\!', '%21', 'g')
	let l:string = substitute(l:string, '\v\#', '%23', 'g')
	let l:string = substitute(l:string, '\v\$', '%24', 'g')
	let l:string = substitute(l:string, '\v\&', '%26', 'g')
	let l:string = substitute(l:string, "\v\'", '%27', 'g')
	let l:string = substitute(l:string, '\v\(', '%28', 'g')
	let l:string = substitute(l:string, '\v\)', '%29', 'g')
	let l:string = substitute(l:string, '\v\*', '%2a', 'g')
	let l:string = substitute(l:string, '\v\+', '%2b', 'g')
	let l:string = substitute(l:string, '\v\,', '%2c', 'g')
	let l:string = substitute(l:string, '\v\/', '%2f', 'g')
	let l:string = substitute(l:string, '\v\:', '%3a', 'g')
	let l:string = substitute(l:string, '\v\;', '%3b', 'g')
	let l:string = substitute(l:string, '\v\=', '%3d', 'g')
	let l:string = substitute(l:string, '\v\?', '%3f', 'g')
	let l:string = substitute(l:string, '\v\@', '%40', 'g')
	let l:string = substitute(l:string, '\v\[', '%5b', 'g')
	let l:string = substitute(l:string, '\v\]', '%5d', 'g')

	return l:string
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
