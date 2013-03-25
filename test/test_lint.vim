let s:outputs = []

function! s:write(qflist)
  for l:qf in a:qflist
    if has_key(l:qf, 'filename')
      let l:qf.filename = fnamemodify(l:qf.filename, ':.')
      call add(s:outputs, printf('%d %d %s %s', l:qf.lnum, l:qf.col, l:qf.filename, l:qf.text))
    endif
  endfor
  call add(s:outputs, '######')
endfunction

function! s:write_async()
  let l:callback = {}
  function! l:callback.on_finish(qflist)
    let self.active = 0
    call s:write(a:qflist)
  endfunction

  let l:callback.active = 1
  call ghcmod#async_make('lint', expand('%:p'), l:callback)
  while l:callback.active
    sleep 100m
    " XXX:
    doautocmd CursorHold
  endwhile
endfunction

function! s:main()
  edit test/data/with-cabal/src/Foo/Bar.hs
  call s:write(ghcmod#make('lint', expand('%:p')))

  edit test/data/with-cabal/src/Foo/Bar.hs
  call s:write_async()

  let g:ghcmod_hlint_options = ['-i', 'Evaluate']

  edit test/data/with-cabal/src/Foo/Bar.hs
  call s:write(ghcmod#make('lint', expand('%:p')))

  edit test/data/with-cabal/src/Foo/Bar.hs
  call s:write_async()

  call writefile(s:outputs, 'test/output/lint.out')
endfunction

call s:main()
