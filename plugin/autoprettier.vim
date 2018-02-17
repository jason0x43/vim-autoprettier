if exists('g:loaded_autoprettier')
  finish
endif
let g:loaded_autoprettier = 1

if !exists('g:autoprettier_user_config')
	let g:autoprettier_user_config = fnamemodify('~/.prettierrc', ':p')
endif

let s:job_cwds = {}

" Check whether there's a local prettier config for the current file
function s:prettierCheck()
	" If the current file isn't a prettifiable type, ignore it
	let l:autoprettier_types = get(g:, 'autoprettier_types', [ 'typescript', 'javascript' ])
	if index(l:autoprettier_types, &filetype) == -1
		return
	endif

	let l:filename = expand('<afile>')

	" If the current file is in node_modules, ignore it
	if l:filename =~ '\<node_modules\/'
		return
	endif

	" If we're excluding files with a given name, ignore this file
	let l:autoprettier_exclude = get(g:, 'autoprettier_exclude', [])
	if index(l:autoprettier_exclude, l:filename) != -1
		return
	endif

	" See if the file has an associated prettier config that's not the user's
	" default
	let job = jobstart(['prettier', '--find-config-path', expand('<afile>')], {
		\ 'on_stdout': function('s:prettierCheckStdout'),
		\ 'on_exit': function('s:prettierCheckDone')
		\ })
	" Store the current cwd. Prettier will return a relative path, and the
	" cwd change betwen now and when the check completes.
	let s:job_cwds[job] = getcwd()
endfunction

" Handle the result of the prettier config check
function s:prettierCheckStdout(job_id, text, event)
	let l:relpath = a:text[0]
	let l:path = fnamemodify(s:job_cwds[a:job_id] . '/' . l:relpath, ':p')
	" If the config associated with a file is the global config, we don't want
	" to auto-prettify
	if l:path == g:autoprettier_user_config
		let b:use_prettier = 0
	endif
endfunction

" Handle the result of the prettier config check
function s:prettierCheckDone(job_id, code, event)
	call remove(s:job_cwds, a:job_id)
	if a:code == 0 && !exists('b:use_prettier')
		let b:use_prettier = 1
	endif
endfunction

" Filter the current file through prettier
function s:prettierSave()
	" If this file shouldn't use prettier, do nothing
	if !exists('b:use_prettier') || !b:use_prettier
		return
	endif

	Prettier
endfunction

" Autocommands to check for prettier and to process files
autocmd FileType * call s:prettierCheck()
autocmd BufWritePre * call s:prettierSave()
