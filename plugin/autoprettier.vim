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
  let l:filename = expand('<afile>')
  if empty(l:filename)
    let l:filename = expand('%')
  endif

  if exists('b:autoprettier_checked')
    return
  endif

  " Don't check the current buffer more than once
  let b:autoprettier_checked = 1

  " If the current file is in node_modules, ignore it
  if l:filename =~# '\<node_modules\/'
    return
  endif

  " If we're excluding files with a given name, ignore this file
  let l:autoprettier_exclude = get(g:, 'autoprettier_exclude', [])
  for pat in l:autoprettier_exclude
    if l:filename =~ glob2regpat(pat)
      return
    endif
  endfor

  " See if the file has an associated prettier config that's not the user's
  " default
  let b:job_stdout = ''
  let job = jobstart(['prettier', '--find-config-path', l:filename], {
        \ 'on_stdout': function('s:prettierCheckStdout'),
        \ 'on_exit': function('s:prettierCheckDone'),
        \ 'stdout_buffered': 1
        \ })

  " Store the current cwd. Prettier will return a relative path, and the cwd
  " changes between now and when the check completes.
  let s:job_cwds[job] = getcwd()
endfunction

" Handle the result of the prettier config check
function s:prettierCheckStdout(job_id, text, event)
  let b:job_stdout = a:text[0]
endfunction

" Handle the result of the prettier config check
function s:prettierCheckDone(job_id, code, event)
  if a:code != 0
    let b:use_prettier = 0
  endif

  let l:relpath = b:job_stdout
  let l:path = fnamemodify(s:job_cwds[a:job_id] . '/' . l:relpath, ':p')

  " If the config associated with a file is the global config, we don't want
  " to auto-prettify
  let b:use_prettier = l:path != g:autoprettier_user_config

  call remove(s:job_cwds, a:job_id)
endfunction

" Filter the current file through prettier
function s:prettierSave()
  " If this file shouldn't use prettier, do nothing
  if !get(b:, 'use_prettier', 0)
    return
  endif

  PrettierAsync
endfunction

function s:refresh()
  unlet b:use_prettier
  unlet b:autoprettier_checked
  call s:prettierCheck()
endfunction

" Autocommands to check for prettier and to process files
augroup Autoprettier
  autocmd!

  let autoprettier_types = get(g:, 'autoprettier_types', [ 'typescript', 'javascript' ])
  execute 'autocmd FileType ' . join(autoprettier_types, ',') . ' call s:prettierCheck()'

  autocmd BufWritePre * call s:prettierSave()
augroup END

command! AutoPrettierRefresh :call s:refresh()
