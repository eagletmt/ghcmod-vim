function! ghcmod#diagnostics#report()
  echomsg 'Current filetype:' &l:filetype
  call s:check_filetype()

  echomsg 'ghcmod.vim version:' join(ghcmod#version(), '.')

  " Note: ghcmod#util#* cannot be used until vimproc.vim's availability is
  " checked.

  let l:ghc_mod = executable('ghc-mod')
  echomsg 'ghc-mod is executable:' l:ghc_mod
  if !l:ghc_mod
    echomsg '  Your $PATH:' $PATH
    return
  endif

  try
    echomsg 'vimproc.vim:' vimproc#version()
  catch /^Vim\%((\a\+)\)\=:E117/
    echomsg 'vimproc.vim is required but not installed'
    return
  endtry

  echomsg 'ghc-mod version:' join(ghcmod#util#ghc_mod_version(), '.')

  if &l:filetype == 'haskell'
    if !exists('b:did_ftplugin_ghcmod')
      call ghcmod#util#print_error("ghcmod.vim's ftplugin isn't loaded. You must copy the `after' directory.")
    endif
  else
    call ghcmod#util#print_warning('Run this command in the buffer opening a Haskell file')
  endif

  let l:cmd = ghcmod#build_command(['debug'])
  echomsg 'ghc-mod debug command:' join(l:cmd, ' ')
  for l:line in split(ghcmod#system(l:cmd), '\n')
    echomsg l:line
  endfor
endfunction

function! s:check_filetype()
  redir => l:ft
  silent filetype
  redir END
  echomsg l:ft[1 :]
  if l:ft !~# 'plugin:ON'
    call ghcmod#util#print_error("You didn't enable filetype plugin. I highly recommend putting `filetype plugin indent on` to your vimrc")
  endif
endfunction
