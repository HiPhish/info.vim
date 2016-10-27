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

" Public interface functions {{{1

" The entry function, invoked by the ':Info' command. Its purpose is to find
" the topic and options from the arguments
function! info#info(mods, ...)
	if a:0 == 0
		let l:topic = ''
	else
		let l:topic = a:1
	endif

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


" Jump to a given node in the document, cannot jump out of the current
" document.
function! info#node(node) abort
	if a:node == ''
		echo s:lineToNode(line('.'), b:toc)
		return
	endif

	if a:node == '(dir)'
		call info#read_doc('info://')
		return
	endif

	if a:node == '-next'
		let l:node = b:nodes[s:lineToNode(line('.'), b:toc)]
		call info#node(l:node['next'])
		return
	endif

	if a:node == '-previous'
		let l:node = b:nodes[s:lineToNode(line('.'), b:toc)]
		call info#node(l:node['prev'])
		return
	endif

	if a:node == '-up'
		let l:node = b:nodes[s:lineToNode(line('.'), b:toc)]
		call info#node(l:node['up'])
		return
	endif

	if type(a:node) == type('')
		if !exists('b:nodes[a:node]')
			throw 'Node '.a:node.' not registered in this document.'
		endif

		let l:lnum = b:nodes[a:node]['line']
		silent execute 'normal '.l:lnum.'G'
		silent! normal zozt
	else
		throw 'Error: node must be a string'
	endif
endfunction


" Populate the location list with all the nodes reflecting the tree structure
" of the TOC.
function! info#toc(mods)
	if &modified
		let b:toc_dirty = 1
		call s:build_toc
	endif

	for entry in b:toc
		call s:prettyPrintTOC(entry, 0)
	endfor

	execute a:mods . ' lopen'
endfunction

" predicate function, tests whether a line is a node header or not
function! info#IsNodeHeader(line)
	return !empty(matchstr(a:line, '\v^\s*((File|Node|Next|Prev|Up)\:\s*[^,]+\,?\s*)+$'))
endfunction



" Private functions for reading info documents {{{1

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

    " Initialise the TOC tree and node dictionary to empty, they will be
    " filled up later. See the code about folding for details. The lock
    " variable will be set after the TOC has been built.
    let b:toc_dirty = 1
    call s:build_toc()

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



" Functions related to the TOC {{{1
"
" The nodes of an info document form a tree structure, every node has a
" parent, a predecessor (which may be the parent) and a successor (which will
" be the first child for the root node). All we have to do is find the node
" headers, take them apart and make the right decision based on that
" information.
"
" This is what a node header looks like:
"  'File: bash.info,  Node: Top,  Next: Introduction,  Prev: (dir),  Up: (dir)'
" We can easily extract the important parts via regex and then compare them to
" previous nodes extracted so far.
"
" We have two structures to keep track of the nodes: the first one is a flat
" dictionary called 'nodes'; it maps the name of each node to its
" corresponding node information. The dictionary structure makes it easy to
" find a particular node. The second structure is a list called 'toc', it is
" the tree of nodes; the list contains dictionaries where the first key is the
" name of the node and the second value is the sub-tree of that node (or an
" empty list for leaf nodes).
"
" The list makes it easy to iterate over the nodes to when the tree-structure
" is important to have, such as when printing out the TOC. The dictionary is
" easy for finding one particular node by its name and accessing its
" information, such as when you need the line number to jump to that
" particular node.

" Build the entire TOC tree and node dictionary.
function! s:build_toc()
	if !b:toc_dirty
		return
	endif

	" We will work on freshly reset values
	let b:nodes = {}
	let b:toc = []

	for l:lnum in range(1, line('$'))
		let l:thisline = getline(l:lnum)

		if !info#IsNodeHeader(l:thisline)
			continue
		endif

		" Extracting all the information from the line for later use
		let l:node = matchstr(l:thisline, '\v(Node: )@<=[^,]+')
		let l:next = matchstr(l:thisline, '\v(Next: )@<=[^,]+')
		let l:prev = matchstr(l:thisline, '\v(Prev: )@<=[^,]+')
		let l:up   = matchstr(l:thisline,   '\v(Up: )@<=[^,]+')

		" The '(dir)' node is special in that any node that has it as the parent
		" is the top-most node of the document.
		if l:up =~? '(dir)'
			let l:path = s:AddNodeToTOC(l:node, '')
		elseif exists('b:nodes[l:up]')
			let l:path = s:AddNodeToTOC(l:node, l:up)
		else
			return '='
		endif

		" After the node has been added to the TOC tree we also have to add it to
		" the flat nodes databse
		let b:nodes[l:node] = {'up': l:up, 'prev': l:prev, 'next': l:next,
					\ 'line': l:lnum, 'path': l:path}

		let b:last_node_line = l:lnum
	endfor

	let b:toc_dirty = 0
endfunction

" Insert a node into the TOC tree based on its parent. Returns the path of
" that node.
function! s:AddNodeToTOC(node, parent)
	" An empty parent signifies a root node.
	if empty(a:parent)
		call add(b:toc, {'node': a:node, 'tree': []})
		return [0]
	endif

	let l:parent_path = b:nodes[a:parent]['path']
	let l:parent_tree = s:FindTOCEntry(l:parent_path)['tree']
	call add(l:parent_tree, {'node': a:node, 'tree': []})
	return add(l:parent_path[:], len(l:parent_tree) - 1)
endfunction

" Find and return an entry inside the TOC based on its path.
function! s:FindTOCEntry(path)
	if empty(a:path)
		throw 'Empty TOC path'
	endif

	" Recursing down the TOC: at each sub-tree we get the entry of the current
	" index, then recurse down its sub-tree.
	let l:tree = b:toc
	for p in a:path
		let l:entry = l:tree[p]
		let l:tree = l:entry['tree']
	endfor

	return l:entry
endfunction

" Return the name of the node of the current line.
function! s:lineToNode(line, tree)
	" The TOC is a non-binary tree and we will perform a binary search on it.
	" First search the current level until we have reduced it to one node,
	" then check that one node, and if it isn't the one we want recurse down
	" into its sub-tree.
	"
	" If the current line number is lower than that of a given node we know
	" that that node and any of its children, later siblings and their
	" children are out of the question.

	let l:len = len(a:tree)

	" The one lone node the root of a new sub-tree.
	if l:len == 1
		let l:tree = a:tree[0]['tree']
		" Three cases:
		"   - Leaf node: found the node
		"   - Line is above the first child: found the node
		"   - Else: Descend down the sub-tree.
		if empty(l:tree)
			return a:tree[0]['node']
		elseif a:line < b:nodes[l:tree[0]['node']]['line']
			return a:tree[0]['node']
		else
			return s:lineToNode(a:line, l:tree)
		endif
	endif

	" Perform a binary search on the current level
	let l:pivot = a:tree[l:len / 2]

	" Three cases:
	"   - The line is the line of the pivot node
	"   - The line is above the pivot -> recurse upper half
	"   - The line is below the pivot -> recurse lower half
	if a:line == b:nodes[l:pivot['node']]['line']
		return l:pivot['node']
	elseif a:line > b:nodes[l:pivot['node']]['line']
		return s:lineToNode(a:line, a:tree[l:len / 2 :])
	else
		return s:lineToNode(a:line, a:tree[: l:len / 2 - 1])
	endif

endfunction

" A helper function used by 'displayTOC' recursively.
function! s:prettyPrintTOC(entry, level)
	let l:node = b:nodes[a:entry['node']]

	let l:msg  = repeat(' ', len(b:last_node_line.'') - len(l:node['line'].''))
	let l:msg .= repeat('  ', a:level)
	let l:msg .= s:pathToNumbers(l:node).' '. a:entry['node']

	laddexpr expand('%').'\|'.l:node['line'].'\|'. ' : '. l:msg

	for l:sub_node in a:entry['tree']
		call s:prettyPrintTOC(l:sub_node, a:level + 1)
	endfor
endfunction

" Helper function, converts a node path to a number sequence like [0, 1, 2] to
" '1.2.3.'
function! s:pathToNumbers(node)
	let l:path = a:node['path']
	if len(l:path) == 1
		return ''
	endif

	let l:string = ''
	for index in l:path[1:]
		let l:string .= (index + 1) . '.'
	endfor
	return l:string
endfunction

" vim:tw=78:ts=4:noexpandtab:norl:
