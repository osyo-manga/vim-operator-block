scriptencoding utf-8
if exists('g:loaded_operator_block')
  finish
endif
let g:loaded_operator_block = 1

let s:save_cpo = &cpo
set cpo&vim


call operator#user#define('block-yank',   'operator#block#yank')
call operator#user#define('block-paste',  'operator#block#paste')
call operator#user#define('block-delete', 'operator#block#delete')



let &cpo = s:save_cpo
unlet s:save_cpo
