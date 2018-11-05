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
"
" About info syntax
" =================
"
" An info file is plain text with some very minimal markup. The most prominent
" part is the *node header*, one line of text at the beginning of every node,
" consisting of `key: value` pairs. The keys can be used to identify the
" related nodes of the current node.
"
" There are two types of info buffers: ones read from from an actual info file
" and ones generated from one or more files by the Info command.

scriptencoding utf-8

if exists('b:current_syntax')
	finish
endif


" Menu markup {{{

" A menu begins with such a line; other text can follow the colon
syntax match infoMenu '\v^\* Menu\:'

" Menu entries have two forms: '* Name: Node.' and '* Node::'
syntax match infoMenuEntry '\v^\*\s+.{-}\:(:|\s+.{-}(,|\. |:|	|$))'

" }}}


" Block-level markup may only appear on its own {{{

" Header at the beginning of every node
syntax match infoHeader '\v^((File|Node|Next|Prev|Up)\:\s*[^,]+,?\s*)+'
" Substitute the items contained in the header
syntax match infoFile  "\vFile:\s+" containedin=infoHeader transparent contained conceal
syntax match infoNode  "\vNode:\s*\ze " containedin=infoHeader transparent contained conceal cchar=◼︎
syntax match infoNext  "\vNext:\s*\ze " containedin=infoHeader transparent contained conceal cchar=▶︎
syntax match infoPrev  "\vPrev:\s*\ze " containedin=infoHeader transparent contained conceal cchar=◀︎
syntax match infoUp    "\vUp:\s*\ze "   containedin=infoHeader transparent contained conceal cchar=▲
syntax match infoComma "\v,\ze  "   containedin=infoHeader transparent contained conceal cchar= 

for item in ['File', 'Node', 'Next', 'Prev', 'Up']
	" exe 'syntax region info'.item.' matchgroup=derp start="\v'.item.':\s+" end="\v\,|$" containedin=infoHeader transparent contained concealends'
endfor

" Section titles, normal text followed by underline characters on next line
" Note: We do not recognise headings with indentation.
syntax match infoHeading '\v^\S.+\n[*.=-]+$'

" Footnotes
syntax match infoFootnotes '\v^\s+\-+ Footnotes \-+$'

" }}}


" Inline markup may appear anywhere in text {{{

" References look like *Note Foo:: or *Note Foo Bar: (foo)Bar.
syntax match infoXRef '\v\*[Nn]ote\_.{-1,}(\:\:|[\.,])'

" }}}


" This is needed to make the multi-line matches work
syntax sync minlines=5 linebreaks=2

highlight link infoHeading           Label
highlight link infoHeader          Special
highlight link infoFootnotes         Label
highlight link infoXRef         Identifier
" highlight link infoLiteral          String
highlight link infoMenu              Label
highlight link infoMenuEntry    Identifier

let b:current_syntax = 'info'

" vim:tw=78:ts=4:noexpandtab:norl:
