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

function! health#info#check() abort
	let l:infoprg = get(b:,'infoprg',get(t:,'infoprg',get(g:,'infoprg','info')))
	call health#report_start('info.vim')

	let l:version = matchstr(system([l:infoprg, '--version']), '\v\d+\.\d+')
	let l:major = matchstr(l:version, '\v\zs\d+\ze\.\d+')
	let l:minor = matchstr(l:version, '\v\d+\.\zs\d+\ze')

	if empty(l:version)
		let l:msg  = 'No standalone info binary found.'
		let l:sug1 = 'Install at least version 6.4 of GNU Texinfo.'
		let l:sug2 = 'Set ''g:infoprg'' to the path of the standalone info binary.'
		call health#report_error(l:msg, [l:sug1, l:sug2])
	elseif l:major < 6 || l:minor < 4
		let l:msg = 'You need at least version 6.4 of standalone info.'
		let l:sug1 = 'Install at least version 6.4 of GNU Texinfo.'
		let l:sug2 = 'Set ''g:infoprg'' to the path of the standalone info binary.'
		call health#report_error(l:msg, [l:sug1, l:sug2])
	else
		call health#report_ok('Version '.l:version.' of standalone info installed.')
	endif
endfunction
