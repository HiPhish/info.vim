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

if exists('g:loaded_info')
  finish
endif


if !has_key(s:, 'did_load')
	" Fallback action if the file is not found
	function! s:fallback(topic, mods)
		echohl ErrorMsg
		echo 'Info.vim: falling back to manpage'
		echohl NONE
		if !has('nvim')
			runtime ftplugin/man.vim
		endif
		execute a:mods 'Man' a:topic
	endfunction
	if !exists('g:Infofallback')
		let g:Infofallback = function('s:fallback')
	endif
endif

" A handy function for constructing function names that use <SID>
function! s:SID()
	return matchstr(expand('<sfile>'), '\v\<SNR\>\d+_')
endfunction

" Lazy loading: First only the Info command is defined; when the command is
" called this script is sourced a second time, executing the rest of it.
if !exists('s:did_load')
	command! -nargs=* Info call <SID>info(<q-mods>, <f-args>)
	let s:did_load = 1
	augroup InfoLazyLoading  " These load the rest of script as needed
		autocmd!
		exe 'autocmd FuncUndefined *info    source '.expand('<sfile>')
		exe 'autocmd BufReadCmd    info:* source '.expand('<sfile>').
		    \'| call ' . s:SID() . 'readReference(info#uri#decode(expand("<afile>")))'
	augroup END
	finish
endif

let g:loaded_info = 1
autocmd! InfoLazyLoading
augroup! InfoLazyLoading

" Path to the documentation in Info format
let s:doc_path = expand('<sfile>:p:h:h').'/doc/'


" Public interface {{{1
nnoremap <silent> <Plug>(InfoUp)      :InfoUp<CR>
nnoremap <silent> <Plug>(InfoNext)    :InfoNext<CR>
nnoremap <silent> <Plug>(InfoPrev)    :InfoPrev<CR>
nnoremap <silent> <Plug>(InfoMenu)    :<C-U>call <SID>menuPrompt(v:count)<CR>
nnoremap <silent> <Plug>(InfoFollow)  :<C-U>call <SID>followPrompt(v:count)<CR>
nnoremap <silent> <Plug>(InfoGoto)    :call <SID>gotoPrompt()<CR>

augroup InfoFiletype
	autocmd!

	" Set up commands for navigating manuals
	autocmd FileType info command! -buffer
		\ -complete=customlist,<SID>completeMenu -nargs=?
		\ Menu call <SID>menu(<q-args>)

	autocmd FileType info command! -buffer
		\ -complete=customlist,<SID>completeFollow -nargs=?
		\ Follow call <SID>follow(<q-args>)

	autocmd FileType info command! -buffer -nargs=?
		\ GotoNode call <SID>gotoNode(<q-args>)

	" Look up the reference under the cursor (for cross-references and menus)
	autocmd FileType info if &buftype =~? 'nofile' | 
			\nnoremap <silent> <buffer> K :call <SID>xRefUnderCursor()<CR> | 
			\nnoremap <silent> <buffer> <2-LeftMouse> :call <SID>xRefUnderCursor()<CR> | 
			\nnoremap <silent> <buffer> <C-]> :call <SID>xRefUnderCursor()<CR> | 
		\endif

	" Opening a file with Info URI
	autocmd BufReadCmd info:* call <SID>readReference(info#uri#decode(expand('<afile>')))
augroup END



" Completion function {{{1

" Filter the list for of candidates for entries which match non-magic,
" case-insensitive and only at the beginning of the string.
function! s:completePrompt(ArgLead, list)
	let l:candidates = map(copy(a:list), {idx, val -> val['Name']})
	if empty(a:ArgLead)
		return l:candidates
	endif
	return filter(l:candidates, {idx,val->!empty(matchstr(val,'\c\M^'.a:ArgLead))})
endfunction

function! s:completeMenu(ArgLead, CmdLine, CursorPos)
	return s:completePrompt(a:ArgLead, b:info['Menu'])
endfunction

function! s:completeFollow(ArgLead, CmdLine, CursorPos)
	return s:completePrompt(a:ArgLead, b:info['XRefs'])
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

	let l:reference = {}
	if !empty(l:file)
		let l:reference['File'] = l:file
	endif
	if !empty(l:node)
		let l:reference['Node'] = l:node
	endif

	if !s:verifyReference(l:reference)
		if exists('g:Infofallback')
			call g:Infofallback(l:file, a:mods)
		endif
		return
	endif

	let l:uri = info#uri#encode(l:reference)

	" The following will trigger the autocommand of editing an info: file
	if a:mods !~# 'tab' && s:find_info_window()
		execute 'silent edit' info#uri#exescape(l:uri)
	else
		execute 'silent' a:mods 'split' info#uri#exescape(l:uri)
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
	setlocal buftype=nofile
	setlocal modifiable

	" Make sure to redirect the standard error into the void
	let l:cmd = s:encodeCommand(a:ref, {'stderr': '/dev/null'})

	put =system(l:cmd)
	" Putting has produced an empty line at the top, remove that
    silent keepjumps 1delete _

	" Parse the node header
	let b:info = {}

	" We assume that the header is the first line. Split the header into
	" key-value pairs.
	let l:headerPairs = split(getline(1), ',')

	for l:pair in l:headerPairs
		" A key is terminated by a colon and might have leading whitespace.
		let l:key = matchstr(l:pair, '\v^\s*\zs[^:]+\ze\:')
		if empty(l:key)
			continue
		endif
		" The value might have leading whitespace as well
		let l:value = matchstr(l:pair, '\v\:\s*\zs[^,]+')
		let b:info[l:key] = l:value
	endfor

	" Parse the raw string into a proper reference
	for l:property in ['Up', 'Next', 'Prev']
		if !has_key(b:info, l:property)
			continue
		endif
		let l:matches = matchlist(b:info[l:property], '\v^(\((.+)\))?(.+)?')
		let [l:file, l:node] = l:matches[2:3] | unlet l:matches
		let b:info[l:property] = {'File': empty(l:file) ? b:info.File : l:file}
		if empty(l:node)
			let b:info[l:property]['Name'] = '('.l:file.')'
		else
			let b:info[l:property]['Name'] = l:node
			let b:info[l:property]['Node'] = l:node
		endif
	endfor

	" Normalise the URI (it might contain abbreviations, but we want full
	" names)
	let l:uri = info#uri#encode({'File': b:info['File'], 'Node': b:info['Node']})

	if bufexists(l:uri) && bufnr(l:uri) != bufnr('%')
		let l:winbufnr = winbufnr(0)
		execute 'silent' 'edit' info#uri#exescape(l:uri)
		execute 'silent '.l:winbufnr.'bwipeout'
	elseif bufname('%') != l:uri
		execute 'silent' 'file' info#uri#exescape(l:uri)
	endif

	" Jump to the given position or second line so header concealing can work
	let l:cursor = [get(a:ref, 'line', 2), get(a:ref, 'column', 1)]
	call cursor(l:cursor)

	" Assemble the menu and cross-references
	call s:buildMenu()
	call s:collectXRefs()

	" Now lock the file, this will set all the remaining options
	setlocal filetype=info
	setlocal nomodifiable
	setlocal readonly
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


" 'Menu' functions {{{1

" If a count is provided jump to that entry without even displaying a prompt.
function! s:menuPrompt(count)
	if !has_key(b:info, 'Menu')
		echohl ErrorMsg
		echo 'No menu in this node.'
		echohl NONE
		return
	endif
	if a:count == 0 || !exists('b:info.Menu[a:count-1]')
		let l:pattern = input('Menu item: ', '', 'customlist,'.s:SID().'completeMenu')
	else
		let l:pattern = b:info.Menu[a:count-1].Node
	endif
	call s:menu(l:pattern)
endfunction

function! s:menu(pattern)
	if !has_key(b:info, 'Menu')
		echohl ErrorMsg
		echo 'No menu in this node.'
		echohl NONE
		return
	endif

	if a:pattern ==# ''
		return s:populateLocList('Menu', b:info['Menu'])
	endif

	let l:entry = s:findReferenceInList(a:pattern, b:info['Menu'])

	if empty(l:entry)
		echohl ErrorMsg
		echo 'Cannot find node ''' . a:pattern . ''''
		echohl None
		return
	endif

	if !s:verifyReference(l:entry)
		return
	endif

	let l:uri = info#uri#encode(l:entry)
	execute 'silent' 'edit' info#uri#exescape(l:uri)
endfunction


" Build up a list of menu entries in a node.
function! s:buildMenu()
	let l:save_cursor = getcurpos()
	let l:menu = []
	let l:menuLine = search('\v^\* [Mm]enu\:')

	if l:menuLine == 0
		return
	endif

	" Process entries by searching down from the menu line. Don't wrap to the
	" beginning of the file or we will be stuck in an infinite loop.
	let l:entryLine = search('\v^\*[^:]+\:', 'W')
	while l:entryLine != 0
		let l:entry = getline(l:entryLine)
		" The line might contain the description of the entry, so we need to
		" strip it out. This is the same regex as used by syntax
		let l:entry = matchstr(l:entry, '\v^\*\s+.{-}\:(:|\s+.{-}(,|\. |:|	|$))')
		call add(l:menu, info#reference#decode(l:entry, b:info))
		let l:entryLine = search('\v^\*[^:]+\:', 'W')
	endwhile

	if !empty(l:menu)
		let b:info['Menu'] = l:menu
	endif

	call setpos('.', l:save_cursor)
endfunction


" 'Follow' functions {{{1

function! s:followPrompt(count)
	if !has_key(b:info, 'XRefs')
		echohl ErrorMsg
		echo 'No cross reference in this node.'
		echohl NONE
		return
	endif

	if !a:count || !exists('b:info.XRefs[a:count-1]')
		let l:firstItem = b:info['XRefs'][0]['Name']
		let l:pattern = input('Follow xref ('.l:firstItem.'): ', '', 'customlist,'.s:SID().'completeFollow')
		if empty(l:pattern)
			let l:pattern = l:firstItem
		endif
		call s:follow(l:pattern)
	else
		call s:follow(b:info.XRefs[a:count-1].Name)
	endif
endfunction

" Follow the cross-reference under the cursor.
function! s:follow(pattern)
	if !has_key(b:info, 'XRefs')
		echohl ErrorMsg
		echo 'No cross reference in this node.'
		echohl NONE
		return
	endif

	if a:pattern ==# ''
		return s:populateLocList('Cross references', b:info['XRefs'])
		return
	endif

	let l:xRef = s:findReferenceInList(a:pattern, b:info['XRefs'])

	if empty(l:xRef)
		echohl ErrorMsg
		echo 'No cross reference matches '''.a:pattern.'''.'
		echohl NONE
		return
	endif

	if !s:verifyReference(l:xRef)
		return
	endif

	let l:uri = info#uri#encode(l:xRef)
	execute 'silent' 'edit' info#uri#exescape(l:uri)
endfunction


function! s:collectXRefs()
	" Pattern to search for (will match over line breaks)
	let l:pattern = '\v\*[Nn]ote\_s*\_[^:]+\:(\_s*\_[^:.,]+[:.,]|\:)'

	let l:save_cursor = getcurpos()
	let l:xRefStrings = []
	let l:xRefs = []

	" This is an ugly hack that modifies the buffer and then undoes the changes.
	setlocal modifiable
	setlocal noreadonly
	silent execute '%s/'.l:pattern.'/\=len(add(l:xRefStrings, submatch(0))) ? submatch(0) : ''''/ge'
	setlocal readonly
	setlocal nomodifiable

	for l:xRefString in l:xRefStrings
		" Due to line breaks the strings might contain newline and multiple
		" spaces, replace them with one space only.
		let l:string = substitute(l:xRefString, '\v\_s+', ' ', 'g')
		let l:xRef = info#reference#decode(l:string, b:info)
		call add(l:xRefs, l:xRef)
	endfor

	if !empty(l:xRefs)
		" Sort items and filter out duplicates
		let b:info['XRefs'] = uniq(sort(l:xRefs, 'i'))
	endif

	call setpos('.', l:save_cursor)
endfunction

" Parse the current line for the existence of a reference element.
function! s:xRefUnderCursor()
	let l:referencePattern = '\v\*([Nn]ote\s+)?\_[^:]+\:(\:|\_[^.,]+[.,])'
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

	" +1 because of space we added
	let l:col = len(getline(line('.') - 1)) + col('.') + 1
	let l:start = 0

	while l:col >= l:start
		" match is zero-indexed, so add one
		let l:start = match(l:line, l:referencePattern) + 1
		let l:end = matchend(l:line, l:referencePattern)

		if l:start < 0 || l:end < 0
			break
		endif

		if l:col < l:end
			let l:xRefString = matchstr(l:line, l:referencePattern)
			let l:xRef = info#reference#decode(l:xRefString, b:info)
			execute 'silent' 'edit' info#uri#exescape(info#uri#encode(l:xRef))
			return
		endif

		let l:line = l:line[l:end :]
		let l:col -= l:end
	endwhile

	echohl ErrorMsg
	echo 'No cross reference under cursor.'
	echohl NONE
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
	let l:ref = {'File': b:info['File'], 'Node': a:node}
	if !s:verifyReference(l:ref)
		return
	endif

	let l:uri = info#uri#encode(l:ref)
	execute 'silent' 'edit' info#uri#exescape(l:uri)
endfunction


" Generally useful functions {{{1

" Return the first reference from 'references' which matches 'pattern'. If
" none match, then return an empty reference.
function! s:findReferenceInList(pattern, references)
	" Try exact matches first
	for l:item in a:references
		if l:item['Name'] ==? a:pattern
			return l:item
		endif
	endfor
	" Prefer matching at the beginning of the pattern
	for l:item in a:references
		if l:item['Name'] =~? '\v^' . a:pattern
			return l:item
		endif
	endfor
	" Finially, try regex matches
	for l:item in a:references
		if l:item['Name'] =~? a:pattern
			return l:item
		endif
	endfor
	return {}
endfunction

" Populate the location list with items from 'items'
function! s:populateLocList(title, items)
	function! ReferenceToEntry(index, reference)
		return {
			\ 'filename': info#uri#encode(a:reference), 
			\ 'lnum': get(a:reference, 'line', 1),
			\ 'text': a:reference.Name,
		\ }
	endfunction
	call setloclist(0, map(copy(a:items), function('ReferenceToEntry')), 'r')
	lopen
	let w:quickfix_title = a:title
endfunction

" Encode a reference into an info command call. The 'kwargs' is for
" redirection of stdin and stderr
function! s:encodeCommand(ref, kwargs)
	let l:cmd = info#prog()
	if has_key(a:ref, 'File')
		let l:cmd .= ' --file '.shellescape(a:ref['File'])
	endif
	if has_key(a:ref, 'Node')
		let l:cmd .= ' --node '.shellescape(a:ref['Node'])
	endif
	" The path to the 'doc' directory has been added so we can find the
	" documents included with the plugin. Output is directed stdout
	let l:cmd .= ' -d '.s:doc_path.' --output -'

	if has_key(a:kwargs, 'stderr')
		let l:cmd .= ' 2>'.a:kwargs['stderr']
	endif

	if has_key(a:kwargs, 'stdout')
		let l:cmd .= ' >'.a:kwargs['stdout']
	endif

	return l:cmd
endfunction

" Check the version of info installed, display a warning if it is too low.
function! s:verifyInfoVersion()
	if exists('s:infoVersion')
		return
	endif

	let l:version = matchstr(system(info#prog() . ' --version'), '\v\d+\.\d+')
	let l:major = matchstr(l:version, '\v\zs\d+\ze\.\d+')

	if l:major < 6
		echohl WarningMsg
		echom 'Warning: Version 6.4+ of standalone info needed, you have '.l:version.'; please set'
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
		if !exists('g:Infofallback')
			echohl ErrorMsg
			echom l:stderr
			echohl NONE
		endif
		return 0
	endif

	return 1
endfunction


" =============================================================================
" vim:tw=78:ts=4:noexpandtab:norl:
