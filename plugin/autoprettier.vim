if exists('g:loaded_autoprettier')
  finish
endif
let g:loaded_autoprettier = 1

" Check whether there's a local prettier config for the current file
function s:prettierCheck()
	" If the current file isn't a prettifiable type, ignore it
	let l:prettier_types = get(g:, 'prettier_types', [ 'typescript', 'javascript' ])
	if index(l:prettier_types, &filetype) == -1
		return
	endif

	" See if the file has an associated prettier config
	call jobstart(['prettier', '--find-config-path', expand('<afile>')], {
		\ 'on_exit': function('s:prettierCheckDone')
		\ })
endfunction

" Handle the result of the prettier config check
function s:prettierCheckDone(job_id, code, event)
	if a:code == 0
		let b:use_prettier = 1
	endif
endfunction

" Filter the current file through prettier
function s:prettierSave()
	" If this file shouldn't use prettier, do nothing
	if !exists('b:use_prettier')
		return
	endif

	Prettier
endfunction

" Autocommands to check for prettier and to process files
autocmd FileType * call s:prettierCheck()
autocmd BufWritePre * call s:prettierSave()
