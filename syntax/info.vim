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
"
" Still to be done:
"   - Description lists
"   - Is it possible to allow anything inside a list? How do we prevent
"     paragraphs inside list items to be confused with literal blocks?
"   - Can we make the indentation of lists and literal blocks smarter? I.e. a
"     literal block needs to be able to understand "I am inside a list, so my
"     indentation should be the indentation of a list (3) plus mine (5)". This
"     also should be able to nest, i.e. have lists inside of lists.
"   - Perhaps it can be useful to math entire nodes as well. A node is a
"     region that starts with a node header and ends with a node separator.
"
" False positives:
"   - Paragraphs in function definitions are mistaken for literal blocks
"
" False negatives:
"   - Literal blocks inside list paragraphs are not recognised

if exists("b:current_syntax")
	finish
endif

" Commonly used regex are stored here for later use
let s:nodeHeaderRegex = '^\s*((File|Node|Next|Prev|Up)\:\s*.+\,?\s*)+$'


syntax keyword infoKeyword File contained
syntax keyword infoKeyword Node contained
syntax keyword infoKeyword Next contained
syntax keyword infoKeyword Prev contained
syntax keyword infoKeyword Up   contained

" Header at the beginning of every node
execute 'syntax match infoNodeHeader /\v'.s:nodeHeaderRegex.'/'

" Section titles, normal text followed by underline characters on next line
syntax match infoSection '\v^(\s*).+\n\1[*.=-]+$'

" URLs are enclosed in angle brackets: <https://example.com/herp-derp/>
syntax match infoURL '\v\<.+\>'

" these are really just regular strings, but inside a toc menu
syntax match infoMenuTitle '\v^[^*	].+$' contained

" Function definitions start with two leading dashes: -- Function print(s)
syntax match infoFunctionDef '\v^ -- .+$'

" Description list: *Some ordinary text*\n
" syntax match infoDescriptionList '\v'


" A table of contents menu
execute 'syntax region infoMenu matchgroup=Label '
			\ . 'start=/\v^\* Menu\:$/ end=/\v('.s:nodeHeaderRegex.')@=/ '
			\ . 'contains=infoMenuEntry,infoMenuTitle,infoFootnotes keepend'

" Similar to a reference, except inside the menu
syntax region infoMenuEntry start='\v\*\s+' end='\v\:\:' contained

" Footnotes
execute 'syntax region infoFootnotes start=/\v^ {3}-+\s+Footnotes?\s+-+$/ '
	\ . 'end=/\v('.s:nodeHeaderRegex.')@=/ keepend'

" References look like *Note topic reference :: or *Note topic reference:
" (foo)Bar.
syntax region infoReference start='\v\*[Nn]ote\s' end='\v\:(\:)|(\s\(\w+\)\w+\.)'

" File path, code literals and so on
syntax region infoLiteral start='\v‘' end='\v’'

" Indented piece of text, but not a list, terminated by an empty line
syntax region infoLiteralBlock
      \ start='\v^\n\z(\s{5,})' skip='^$' end='^\v\z1@!'

" Three spaces, a bullet and one more space. We need to match lists to not
" confuse paragraphs inside lists with literal blocks.
syntax region infoList start='\v^\n\z( {3,})• ' skip='^$'  end='\v^\z1@!'
	\ contains=infoReference,infoLiteral,infoURL


" This is needed to make the multi-line matches work
syn sync minlines=5 linebreaks=2

highlight link infoKeyword        Keyword
highlight link infoSection          Label
highlight link infoNodeHeader     Special
highlight link infoFootnotes         None
highlight link infoFunctionDef       None
highlight link infoURL         Identifier
highlight link infoReference   Identifier
highlight link infoList              None
highlight link infoLiteral         String
highlight link infoLiteralBlock    String
highlight link infoMenuTitle        Label
highlight link infoMenuEntry   Identifier

let b:current_syntax = "info"
