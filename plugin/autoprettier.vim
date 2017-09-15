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

	silent let l:out = systemlist('prettier --stdin --stdin-filepath "' . expand('%') . '"', getline(1, '$'))

	if v:shell_error
		" prettier failed, so just echo the error
		for line in l:out
			echoe line
		endfor
	else
		" Make an edit so that the cursor position will be mainted if the
		" prettification is undone
		" See http://vim.wikia.com/wiki/Restore_the_cursor_position_after_undoing_text_change_made_by_a_script
		normal! ix
		normal! x

		" Save the window state
		let l:view = winsaveview()

		" Delete all lines
		%d

		" Set the first line to the first output line, then append the
		" remaining output lines. This prevents the buffer from having an
		" leading or trailing blank line that wasn't part of the output.
		call setline(1, l:out[0])
		call append(1, l:out[1:])

		" Restore the window state
		call winrestview(l:view)
	endif
endfunction

" Autocommands to check for prettier and to process files
autocmd FileType * call s:prettierCheck()
autocmd BufWritePre * call s:prettierSave()
