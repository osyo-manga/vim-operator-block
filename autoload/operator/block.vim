scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:as_submatch(text)
	return '\(' . a:text . '\)'
endfunction


function! s:parse(text, block)
	let pattern = join(map(copy(a:block), 's:as_submatch(v:val)'), '')
	if a:text !~ pattern
		return []
	endif
	let result = matchlist(a:text, pattern)
	return result[1:3]
endfunction



function! s:get_text_from_region(first, last, ...)
	let wise = get(a:, 1, "v")

	let old_selection = &selection
	let &selection = 'inclusive'

	let register = v:register == "" ? '"' : v:register
	let old_reg = getreg(register)
	let old_first = getpos("'[")
	let old_last  = getpos("']")
	try
		call setpos("'[", a:first)
		call setpos("']", a:last)
		execute printf('normal! `[%s`]y', wise)
		return getreg(register)
	finally
		call setpos("'[", old_first)
		call setpos("']", old_last)
		call setreg(register, old_reg)
		let &selection = old_selection
	endtry
endfunction


function! s:paste_text_in_region(text, first, last, ...)
	let wise = get(a:, 1, "v")

	let old_selection = &selection
	let &selection = 'inclusive'

	let register = v:register == "" ? '"' : v:register
	let old_reg = getreg(register)
	let old_first = getpos("'[")
	let old_last  = getpos("']")
	let old_pos = getpos(".")
	try
		call setpos("'[", a:first)
		call setpos("']", a:last)
		call setreg(register, a:text)
		execute printf('normal! `[%s`]p', wise)
	finally
		call setpos("'[", old_first)
		call setpos("']", old_last)
		call setreg(register, old_reg)
		call setpos(".", old_pos)
		let &selection = old_selection
	endtry
endfunction


function! s:as_wise_key(name)
	return a:name ==# "char"  ? "v"
\		 : a:name ==# "line"  ? "V"
\		 : a:name ==# "block" ? "\<C-v>"
\		 : a:name
endfunction


let s:block_pattern = [
\	['^\k*(', '\_.\{-}', ')$'],
\	['^\k*<', '\_.\{-}', '>$'],
\	['^\k*[', '\_.\{-}', ']$'],
\]


function! s:parses(text, patterns)
	for pattern in a:patterns
		let block = s:parse(a:text, pattern)
		if !empty(block)
			return block
		endif
	endfor
	return []
endfunction


function! s:yank(first, last, wise)
	let text = s:get_text_from_region(a:first, a:last, a:wise)
	let block = s:parses(text, s:block_pattern)
	if empty(block)
		return
	endif
	let register = v:register == "" ? '"' : v:register
	call setreg(register, block[0] . block[2])
endfunction


function! operator#block#yank(wise, ...)
	call s:yank(getpos("'["), getpos("']"), s:as_wise_key(a:wise))
endfunction



function! s:paste(first, last, wise)
	let register = v:register == "" ? '"' : v:register
	let block = s:parses(getreg(register), s:block_pattern)
	if empty(block)
		return
	endif

	let text = s:get_text_from_region(a:first, a:last)
	let text = block[0] . text . block[2]
	call s:paste_text_in_region(text, a:first, a:last, a:wise)
endfunction


function! operator#block#paste(wise, ...)
	call s:paste(getpos("'["), getpos("']"), s:as_wise_key(a:wise))
endfunction



function! s:delete(first, last, wise)
	let text = s:get_text_from_region(a:first, a:last, a:wise)
	let block = s:parses(text, s:block_pattern)
	if empty(block)
		return
	endif
	call s:paste_text_in_region(block[1], a:first, a:last)
	let register = v:register == "" ? '"' : v:register
	call setreg(register, block[0] . block[2])
endfunction


function! operator#block#delete(wise, ...)
	call s:delete(getpos("'["), getpos("']"), s:as_wise_key(a:wise))
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
