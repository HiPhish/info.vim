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

" How it works {{{
" ============
"
" This file does a lot of thins as the same time, so here is my attempt at
" making sense of it. The groups are as follows:
"
"   Public interface: Auto-commands, mappings and commands. Anything that is
"                     meant to be exposed to the user
"
"   Completion functions: Tab-complete commands
"
"   Reading functions: Getting content into the buffer and opening info files
"
"   Navigation functions: Node navigation
"
"   Menu function: Anything related to menus
"
"   Reference function: Anything related to (cross-)references
"
"   URI-handing functions: Anything URI-related
"
" The fundamental idea of this plugin is to use standalone info as much as
" possible and make use of the URI-reference duality. What this means is that
" internally we pass reference objects around, but when it comes to actually
" reading a buffer we send a URI to Vim. Vim tries to open the URI, which
" triggers an auto-command, converting the URI back to a reference and
" allowing the plugin to send the required information to info.
"
" The scheme is:
" 	1) Call ':Info', this generates a URI and find a window
" 	2) Edit the URI
" 	3) This fires and auto-command, converting the URI back to a reference
" 	4) The reference is used for everything else from now
" The first step is optional, it does not matter how we get Vim to ':edit' the
" URI. For instance, when following a reference or going to the next node we
" convert the reference to a URI and ':edit' it in the current window.
" }}}

" Read first before writing code {{{
" ==============================
"
" VimScript is full of ugly pitfalls, and this code is full of ugly
" workarounds, so here is a list of things to look out for.
"
" Executing commands containing a URI
" 	 A URI may contain percent characters (percent encoding), which in an
" 	 ex-command are interpreted as "the current file". For this reason they
" 	 must be escaped. To cut down the redundancy use the 's:executeURI'
" 	 function.
"
" Calling an external tool (e.g. info)
"    External tools are called from the shell, so the command strings needs to
"    be properly escaped. This does not just mean escaping spaces, but also
"    adjusting redirection for different shells. Use the 's:encodeCommand'
"    function.
" }}}


if exists('g:loaded_info')
  finish
endif
let g:loaded_info = 1

" This is the program that assembles info files, we might later decide to make
" it possible to define your own one.
if !exists('g:infoprg')
	let g:infoprg = 'info'
endif


" Public interface {{{1
command! -nargs=* Info call <SID>info(<q-mods>, <f-args>)

nnoremap <silent> <Plug>(InfoUp)      :call <SID>up()<CR>
nnoremap <silent> <Plug>(InfoNext)    :call <SID>next()<CR>
nnoremap <silent> <Plug>(InfoPrev)    :call <SID>prev()<CR>
nnoremap <silent> <Plug>(InfoMenu)    :call <SID>menuPrompt()<CR>
nnoremap <silent> <Plug>(InfoFollow)  :call <SID>followPrompt()<CR>
nnoremap <silent> <Plug>(InfoGoto)    :call <SID>gotoPrompt()<CR>

augroup InfoFiletype
	autocmd!

	autocmd FileType info command! -buffer
		\ -complete=customlist,<SID>completeMenu -nargs=?
		\ Menu call <SID>menu(<q-args>)

	autocmd FileType info command! -buffer
		\ -complete=customlist,<SID>completeFollow -nargs=?
		\ Follow call <SID>follow(<q-args>)

	autocmd FileType info command! -buffer -nargs=?
		\ GotoNode call <SID>gotoNode(<q-args>)

	autocmd FileType info command! -buffer InfoUp    call <SID>up()
	autocmd FileType info command! -buffer InfoNext  call <SID>next()
	autocmd FileType info command! -buffer InfoPrev  call <SID>prev()


	autocmd BufReadCmd info://* call <SID>readReference(<SID>decodeURI(expand('<amatch>')))
augroup END



" Completion function {{{1

" Filter the menu list for entries which match non-magic, case-insensitive and
" only at the beginning of the string.
function! s:completeMenu(ArgLead, CmdLine, CursorPos)
	call s:buildMenu()
	return s:completePrompt(a:ArgLead, a:CmdLine, a:CursorPos, b:info['Menu'])
endfunction

function! s:completeFollow(ArgLead, CmdLine, CursorPos)
	call s:collectXRefs()
	return s:completePrompt(a:ArgLead, a:CmdLine, a:CursorPos, b:info['XRefs'])
endfunction


" 'Info' functions {{{1

" The entry function, invoked by the ':Info' command. Its purpose is to find
" the file and options from the arguments
function! s:info(mods, ...)
	call s:verifyInfoVersion()

	let l:file = ''
	let l:node = ''

	if a:0 > 0
		let l:file = a:1
	endif

	if a:0 > 1
		let l:node = a:2
	endif

	let l:reference = {'file': l:file, 'node': l:node}
	if !s:verifyReference(l:reference)
		return
	endif


	let l:uri = s:encodeURI(l:reference)

	" The following will trigger the autocommand of editing an info:// file
	if a:mods !~# 'tab' && s:find_info_window()
		call s:executeURI('silent edit ', l:uri)
	else
		call s:executeURI('silent '.a:mods.' split ', l:uri)
	endif

	echo 'Welcome to Info. Type g? for help.'
endfunction


" Jump to a particular reference. Here the heavy heavy lifting happens: we set
" the options for the buffer and load the info document.
function! s:readReference(ref)
	call s:verifyInfoVersion()

	if !s:verifyReference(a:ref)
		" The first buffer is special: If there is no content Vim will reuse
		" it for our edit, that's why we can't just wipe it out
		if bufnr('%') == 1
			silent file [No Name]
		else
			silent bwipeout
		endif
		return
	endif

	" We will lock it after assembly
	setlocal modifiable
	setlocal readonly
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=hide

	" Make sure to redirect the standard error into the void
	let l:cmd = s:encodeCommand(a:ref, {'stderr': '/dev/null'})

	put =system(l:cmd)
	" Putting has produced an empty line at the top, remove that
    silent keepjumps 1delete _

    silent keepjumps normal! gg

	" Parse the node header
	let b:info = {}

	" We assume that the header is the first line. Split the header into
	" key-value pairs.
	let l:headerPairs = split(getline(1), ',')

	for l:pair in l:headerPairs
		" A key is terminated by a colon and might have leading whitespace.
		let l:key = matchstr(l:pair, '\v^\s*\zs[^:]+')
		" The value might have leading whitespace as well
		let l:value = matchstr(l:pair, '\v^\s*[^:]+\:\s*\zs[^,]+')
		let b:info[l:key] = l:value
	endfor

	" Normalise the URI (it might contain abbreviations, but we want full
	" names)
	let l:uri = s:encodeURI({'file': b:info['File'], 'node': b:info['Node']})

	if bufexists(l:uri) && bufnr(l:uri) != bufnr('%')
		let l:winbufnr = winbufnr(0)
		call s:executeURI('silent edit ', l:uri)
		execute 'silent '.l:winbufnr.'bwipeout'
	elseif bufname('%') != l:uri
		call s:executeURI('silent file ', l:uri)
	endif

	" Jump to the given line
	let l:cursor = [
		\ exists('a:ref[''line'']'  ) ? a:ref['line'  ] : 1,
		\ exists('a:ref[''column'']') ? a:ref['column'] : 1
	\ ]
	call cursor(l:cursor)

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
	let l:thiswin = winnr()
	while 1
		wincmd w
		if &filetype ==# 'info'
			return 1
		elseif l:thiswin ==# winnr()
			return 0
		endif
	endwhile
endfunction


" Navigation functions (up, next, prev) {{{1

" Jump to the next node
function! s:next()
	call s:jumpToProperty('Next')
endfunction

" Jump to the next node
function! s:prev()
	call s:jumpToProperty('Prev')
endfunction

" Jump to the next node
function! s:up()
	call s:jumpToProperty('Up')
endfunction

" Common code for next, previous, and so on nodes
function! s:jumpToProperty(property)
	if !exists('b:info['''.a:property.''']')
		echohl ErrorMsg
		echo 'No '''.a:property.''' pointer for this node.'
		echohl None
		return
	endif

	" The node name might contain a file name: (file)Node
	let l:property = b:info[a:property]

	let l:file = matchstr(l:property, '\v^\(\zs[^)]+\ze\)')
	if empty(l:file)
		let l:file = b:info['File']
	endif

	let l:node = matchstr(l:property, '\v^(\([^)]*\))?\zs.+')
	if empty(l:node)
		let l:node = 'Top'
	endif

	let l:uri = s:encodeURI({'file': l:file , 'node': l:node})
	call s:executeURI('silent edit ', l:uri)
endfunction


" 'Menu' functions {{{1

function s:menuPrompt()
	let l:pattern = input('Menu item: ', '', 'customlist,'.s:SID().'completeMenu')
	call s:menu(l:pattern)
endfunction

function! s:menu(pattern)
	call s:buildMenu()

	if a:pattern ==# ''
		call setloclist(0, [], ' ', 'Menu')

		for l:item in b:info['Menu']
			if exists('l:item[''line'']')
				let l:line = l:item['line']
			else
				let l:line = 1
			endif

			let l:uri = s:encodeURI(l:item)
			laddexpr l:uri.'\|'.l:line.'\| '.l:item['name']
		endfor

		lopen
		return
	endif

	let l:entry = s:findReferenceInList(a:pattern, b:info['Menu'])

	if empty(l:entry)
		echohl ErrorMsg
		echo 'Cannot find menu entry ' . a:pattern
		echohl None
		return
	endif

	let l:uri = s:encodeURI(l:entry)
	call s:executeURI('silent edit ', l:uri)
endfunction


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
		call add(b:info['Menu'], s:decodeRefString(getline(l:entryLine)))
		let l:entryLine = search('\v^\*[^:]+\:', 'W')
	endwhile

	call setpos('.', l:save_cursor)
endfunction


" 'Follow' functions {{{1

function s:followPrompt()
	call s:collectXRefs()
	if empty(b:info['XRefs'])
		echohl ErrorMsg
		echo 'No cross references in this node.'
		echohl NONE
		return
	endif

	let l:firstItem = b:info['XRefs'][0]['name']
	let l:pattern = input('Follow xref ('.l:firstItem.'): ', '', 'customlist,'.s:SID().'completeFollow')
	if empty(l:pattern)
		let l:pattern = l:firstItem
	endif
	call s:follow(l:pattern)
endfunction

" Follow the cross-reference under the cursor.
function! s:follow(pattern)
	if a:pattern ==# ''
		let l:xRef = s:xRefUnderCursor()
	else
		call s:collectXRefs()
		let l:xRef = s:findReferenceInList(a:pattern, b:info['XRefs'])
	endif

	if empty(l:xRef)
		echohl ErrorMsg
		echo 'No cross reference under cursor.'
		echohl NONE
		return
	endif

	let l:uri = s:encodeURI(l:xRef)
	call s:executeURI('silent edit ', l:uri)
endfunction


function! s:collectXRefs()
	if exists('b:info[''XRefs'']')
		return
	endif

	" Pattern to search for (will match over line breaks)
	let l:pattern = '\v\*[Nn]ote\_s*\_[^:]+\:(\_s*\_[^:.]+\.|\:)'

	let l:save_cursor = getcurpos()
	let l:xRefStrings = []
	let l:xRefs = []

	" This is an ugly hack that modifies the buffer and then undoes the changes.
	set modifiable
	set noreadonly
	silent execute '%s/'.l:pattern.'/\=len(add(l:xRefStrings, submatch(0))) ? submatch(0) : ''''/ge'
	set readonly
	set nomodifiable

	for l:xRefString in l:xRefStrings
		" Due to line breaks the strings might contain newline and multiple
		" spaces, replace them with one space only.
		let l:string = substitute(l:xRefString, '\v\_s+', ' ', 'g')
		let l:xRef = s:decodeRefString(l:string)
		call add(l:xRefs, l:xRef)
	endfor


	let b:info['XRefs'] = l:xRefs
	call setpos('.', l:save_cursor)
endfunction

" Parse the current line for the existence of a reference element.
function! s:xRefUnderCursor()
	let l:referencePattern = '\v\*([Nn]ote\s+)?[^:]+\:(\:|[^.]+\.)'
	" Test-cases for the reference pattern
	" *Note Directory: (dir)Top.
	" *Note Directory::
	" *Directory::
	" *Directory: (dir)Top.

	" There can be more than one reference in a line, so we need to find the
	" one which contains the cursor between its ends. Since cross-references
	" can span more than one line we will look at the current, preceding and
	" succeeding line at the same time.
	"
	" Note: We assume that a reference will never span more than two lines.

	let l:line  = getline(line('.') - 1) . ' '
	let l:line .= getline('.'          ) . ' '
	let l:line .= getline(line('.') + 1)

	" The match and matchend are 0-indexed, so we subtract one
	let l:col = len(getline(line('.') - 1)) + col('.') - 1
	let l:start = 0

	while l:col >= l:start
		let l:start = match(l:line, l:referencePattern)
		let l:end = matchend(l:line, l:referencePattern)

		if l:start < 0
			break
		endif

		if l:col < l:end
			let l:xRefString = matchstr(l:line, l:referencePattern)
			let l:xRef = s:decodeRefString(l:xRefString)
			return l:xRef
		endif

		let l:line = l:line[l:end :]
		let l:col -= l:end
	endwhile

	return {}
endfunction



" 'Goto' functions {{{1

" Go to a given node.
function! s:gotoPrompt()
	let l:node = input('Goto node: ')
	if empty(l:node)
		return
	endif

	call s:gotoNode(l:node)
endfunction


" Jump to a given node inside the current file.
function! s:gotoNode(node)
	let l:ref = {'file': b:info['File'], 'node': a:node}
	if !s:verifyReference(l:ref)
		return
	endif

	let l:uri = s:encodeURI(l:ref)
	call s:executeURI('silent edit ', l:uri)
endfunction
" URI-handling function {{{1

" Decodes a URI into a node reference
function! s:decodeURI(uri)
	" URI-parsing regex from [RFC 3986]:
	"    https://tools.ietf.org/html/rfc3986#appendix-B
	let l:uriMatches = matchlist(a:uri, '\v^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?')

	let l:authority = s:percentDecode(l:uriMatches[4])
	let l:path      = s:percentDecode(l:uriMatches[5])
	let l:query     = s:percentDecode(l:uriMatches[7])

	let l:file = empty(l:authority) ? 'dir' : l:authority

	" Strip leading and trailing slashes from the path
	let l:node = substitute(l:path, '\v(^\/)|(\/$)', '', 'g')
	if empty(l:node)
		let l:node = 'Top'
	endif

	let l:line   = matchstr(l:query, '\vline\=\zs\d+')
	let l:column = matchstr(l:query, '\vcolumn\=\zs\d+')

	let l:ref = {'file': l:file, 'node': l:node}

	if !empty(l:line)
		let l:ref['line'] = l:line
	endif

	if !empty(l:column)
		let l:ref['column'] = l:column
	endif

	return l:ref
endfunction


" Encodes a node reference into a URI
function! s:encodeURI(reference)
	let l:file   = ''
	let l:node   = ''
	let l:line   = ''
	let l:column = ''

	if (exists('a:reference[''file'']'))
		let l:file = s:percentEncode(a:reference['file'])
	endif

	if (exists('a:reference[''node'']'))
		let l:node = s:percentEncode(a:reference['node'])
	endif

	if (exists('a:reference[''line'']'))
		let l:line = a:reference['line']
	endif

	if (exists('a:reference[''column'']'))
		let l:line = a:reference['column']
	endif

	let l:uri = 'info://'

	if !empty(l:file)
		let l:uri .= l:file.'/'
		if !empty(l:node)
			let l:uri .= l:node.'/'
		endif
	endif

	if !empty(l:line) || !empty(l:column)
		let l:uri .= '?'
		if !empty(l:line)
			let l:uri .= 'line='.l:line
			if !empty(l:column)
				let l:uri .= '&'
			endif
		endif
		if !empty(l:column)
			let l:uri .= 'column='.l:column
		endif
	endif

	return l:uri
endfunction

function! s:percentEncode(string)
	" Important: encode the percent symbol first
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

function! s:percentDecode(string)
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


" Generally useful functions {{{1

function! s:SID()
	return matchstr(expand('<sfile>'), '\v\<SNR\>\d+_')
endfunction

function! s:findReferenceInList(pattern, list)
	for l:item in a:list
		if l:item['name'] =~? a:pattern
			return l:item
		endif
	endfor
	return {}
endfunction

function! s:completePrompt(ArgLead, CmdLine, CursorPos, list)
	let l:candidates = []

	for l:item in a:list
		" Match only at the beginning of the string
		if empty(a:ArgLead) || !empty(matchstr(l:item['name'], '\c\M^'.a:ArgLead))
			call add(l:candidates, l:item['name'])
		endif
	endfor

	return l:candidates
endfunction

" Parse a reference string into a reference object.
function! s:decodeRefString(string)
	" Strip away the leading cruft first: '* ' and '*Note '
	let l:reference = matchstr(a:string, '\v^\*([Nn]ote\s+)?\s*\zs.+')
	" Try the '* Node::' type of reference first
	let l:name = matchstr(l:reference, '\v^\zs[^:]+\ze\:\:')

	if empty(l:name)
		" The format is '* Name: (file)Node.*
		let l:name = matchstr(l:reference, '\v^\zs[^:]+\ze\:')

		let l:file = matchstr(l:reference, '\v^[^:]+\:\s*\(\zs[^)]+\ze\)')
		" If there is no file the current one is implied
		if empty(l:file)
			let l:file = b:info['File']
		endif

		let l:node = matchstr(l:reference, '\v^[^:]+\:\s*(\([^)]+\))?\zs[^.]+\ze\.')
	else
		let l:node = l:name
		let l:file = b:info['File']
	endif

	return {'name': l:name, 'file': l:file, 'node': l:node}
endfunction


" Encode a reference into an info command call. The 'kwargs' is for
" redirection of stdin and stderr
function s:encodeCommand(ref, kwargs)
	let l:file = shellescape(exists('a:ref[''file'']') ? a:ref['file'] : 'dir')
	let l:node = shellescape(exists('a:ref[''node'']') ? a:ref['node'] : 'Top')

	let l:cmd = g:infoprg.' -f '.l:file.' -n '.l:node.' -o -'

	if exists('a:kwargs[''stderr'']')
		let l:cmd .= ' 2>'.a:kwargs['stderr']
		" Adjust the redirection syntax for special snowflake shells
		if &shell =~# 'fish$'
			let l:cmd = substitute(l:cmd, '\v\zs2\>\ze\/dev\/null$', '^', '')
		endif
	endif

	if exists('a:kwargs[''stdout'']')
		let l:cmd .= ' >'.a:kwargs['stdout']
	endif

	return l:cmd
endfunction


" Call an ex-command with the URI. This will make sure the URI is properly
" escaped.
function! s:executeURI(ex_cmd, uri)
	" We have to escape the percent signs or it will be replaced with the
	" file name in the ':edit'
	let l:uri = substitute(a:uri, '\v\%', '\\%', 'g')
	execute a:ex_cmd l:uri
endfunction


" Check the version of info installed, display a warning if it is too low.
function! s:verifyInfoVersion()
	if exists('s:infoVersion')
		return
	endif

	let l:version = matchstr(system(g:infoprg.' --version'), '\v\d+\.\d+')
	let l:major = matchstr(l:version, '\v\zs\d+\ze\.\d+')
	" let l:minor = matchstr(l:version, '\v\d+\.\zs\d+\ze')

	if l:major < 6
		echohl WarningMsg
		echom 'Warning: Version 6.0+ of standalone info needed, you have '.l:version.'; please set'
		echom 'the ''g:infoprg'' variable to a compatible binary. Info might still work with'
		echom 'your binary, but it is not guaranteed.'
		echohl NONE
	endif

	let s:infoVersion = l:version
endfunction


" Verify that a reference leads to an actual file or node.
function! s:verifyReference(ref)
	" Send the output to the void, we only want the error
	let l:cmd = s:encodeCommand(a:ref, {'stdout': '/dev/null'})
	let l:stderr = system(l:cmd)

	" Info always returns exit code 0, so we have to rely on the error message
	if !empty(l:stderr)
		" The message might contain line breaks.
		let l:stderr = substitute(l:stderr, '\v\_s+', ' ', 'g')
		echohl ErrorMsg
		echom l:stderr
		echohl NONE
		return 0
	endif

	return 1
endfunction
" vim:tw=78:ts=4:noexpandtab:norl:
