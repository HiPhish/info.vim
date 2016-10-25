" Folding and node navigation are both initialised in this script.
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
"
" As for folding, that's simple: If it's not a node header use the previous
" fold level. It it is a node header and it's the top the level is 1,
" otherwise it's the fold level of the parent node plus one.

function! InfoNodeFolds()
	" There is a tricky part here: this function will potentially be run
	" multiple times, which would screw up the TOC tree. Therefore we use a
	" lock variable that's turned after the last line has been processed for
	" the first time, because that's when the TOC is complete. On subsequent
	" runs we skip the whole TOC-building part.

	let l:thisline = getline(v:lnum)

	" Lines that aren't header nodes are always on the same level as the node
	" they belong to
	if !s:IsNodeHeader(l:thisline)
		if v:lnum == line('$')
			let b:toc_was_built = 1
		endif
		return '='
	endif

	" Extracting all the information from the line for later use
	let l:node = matchstr(l:thisline, '\v(Node: )@<=[^,]+')
	let l:next = matchstr(l:thisline, '\v(Next: )@<=[^,]+')
	let l:prev = matchstr(l:thisline, '\v(Prev: )@<=[^,]+')
	let l:up   = matchstr(l:thisline,   '\v(Up: )@<=[^,]+')

	" Avoid rebuilding the TOC, just return how deep into the tree the node is
	if b:toc_was_built
		return '>'.(len(b:nodes[l:node]['path']) - 1)
	endif

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
	let b:nodes[l:node] = {'up': l:up,
				\'prev': l:prev,
				\'next': l:next,
				\'line': v:lnum,
				\'path': l:path}

	let b:last_node_line = v:lnum


	if v:lnum == line('$')
		let b:toc_was_built = 1
	endif
	return '>'.(len(l:path) - 1)
endfunction

" Tests whether a line is a node header or not
function! s:IsNodeHeader(line)
	return !empty(matchstr(a:line, '\v^\s*((File|Node|Next|Prev|Up)\:\s*[^,]+\,?\s*)+$'))
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

" Strip the 'File: foo.info' part from the line
function! s:FoldText()
	return substitute(getline(v:foldstart), '\vFile: [^,]+\,\s*', '', '')
endfunction

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

setlocal foldmethod=expr
setlocal foldexpr=InfoNodeFolds()
l
" vim:tw=78:ts=4:noexpandtab:net &l:foldtext = s:SID() . 'FoldText()'
