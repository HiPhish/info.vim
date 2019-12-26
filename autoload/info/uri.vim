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

" URI-related functions, primarily encoding and decoding of URIs. See RFC 3986
" for the general URI specification, and the GNU Texinfo manual for the
" proposal of Info URIs.
"
"   https://tools.ietf.org/html/rfc3986
"   info:texinfo.info#Info%20Files


" ===[ constants ]=============================================================
" URI-parsing regex from https://tools.ietf.org/html/rfc3986#appendix-B
let s:uri_regex = '\v^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?'

" Maps a character to its percent code. Does not include the '%' because that
" one needs special handling.
let s:char_to_code = [
	\ [' ', '20'], ['!', '21'], ['#', '23'], ['$', '24'], ['&', '26'],
	\ ["'", '27'], ['(', '28'], [')', '29'], ['*', '2a'], ['+', '2b'],
	\ [',', '2c'], ['/', '2f'], [':', '3a'], [';', '3b'], ['=', '3d'],
	\ ['?', '3f'], ['@', '40'], ['[', '5b'], [']', '5d'],
\ ]


" ===[ functions ]=============================================================
" Escape the URI string characters such that the string can be used inside an
" ex-command. A URI may contain percent characters (percent encoding), which in
" an ex-command are interpreted as 'the current file'. For this reason they
" must be escaped.
function! info#uri#exescape(uri)
	let l:uri = substitute(a:uri, '\v\\', '\\\\', 'g')
	let l:uri = substitute(l:uri, '\v\#',  '\\#', 'g')
	" Percent characters stand for the current file name
	let l:uri = substitute(l:uri, '\v\%', '\\%', 'g')
	return l:uri
endfunction

" Decodes a URI into a node reference
function! info#uri#decode(uri)
	let l:uriMatches = matchlist(a:uri, s:uri_regex)

	let l:path     = s:percentDecode(l:uriMatches[5])
	let l:query    = s:percentDecode(l:uriMatches[7])
	let l:fragment = s:percentDecode(l:uriMatches[9])

	let l:ref = {'File': l:path}

	if !empty(l:fragment)
		let l:ref['Node'] = l:fragment
	endif

	for l:prop in ['line','column']
		let l:val = matchstr(l:query, '\v'..l:prop..'\=\zs\d+')
		if !empty(l:val)
			let l:ref[l:prop] = l:val
		endif
	endfor

	return l:ref
endfunction


" Encodes a node reference into a URI
function! info#uri#encode(reference)
	" The scheme is hard-coded, the path has a mandatory default
	let l:uri = 'info:' .. s:percentEncode(get(a:reference, 'File', 'dir'))

	" Build up the query dictionary
	let l:query_props = ['line', 'column']  " Hard-coded URI properties
	let l:query  = {}
	for l:prop in l:query_props
		if get(a:reference, l:prop, 0)
			let l:query[l:prop] = get(a:reference, l:prop)
		endif
	endfor
	" Insert the query into the URI
	if !empty(l:query)
		let l:uri .= '?'
		for [l:prop, l:val] in items(l:query)
			let l:uri .= l:prop .. '=' .. l:val .. '&'
		endfor
		let l:uri = l:uri[:-2]  " Strip away the last '&'
	endif

	" Insert the fragment into the URI
	if has_key(a:reference, 'Node')
		let l:uri .= '#' .. s:percentEncode(get(a:reference, 'Node'))
	endif

	return l:uri
endfunction


" ===[ helper functions ]======================================================
function! s:percentEncode(string)
	" Important: encode the percent symbol first
	let l:string = substitute(a:string, '\v\%', '%25', 'g')
	for [l:char, l:code] in s:char_to_code
		let l:string = substitute(l:string, '\v\'..l:char, '%'..l:code, 'g')
	endfor

	return l:string
endfunction

function! s:percentDecode(string)
	" Important: Decode the percent symbol last
	let l:string = a:string
	for [l:code, l:char] in s:char_to_code
		let l:string = substitute(l:string, '\v\%'..l:char, l:code, 'g')
	endfor
	return substitute(l:string, '\v\%25', '%', 'g')
endfunction
