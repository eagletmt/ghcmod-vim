let s:outputs = []

function! s:capture(cmd)
  let l:result = ''
  redir => l:result
  silent execute a:cmd
  redir END
  return split(l:result, '\n')
endfunction

function! s:match_group(match_id)
  for l:item in getmatches()
    if l:item.id == a:match_id
      return l:item.group
    endif
  endfor
  return ''
endfunction

function! s:write()
  let [l:type] = s:capture('GhcModType')
  call add(s:outputs, printf('%s %s', s:match_group(b:ghcmod_type.match_id), l:type))
endfunction

function! s:main()
  " default highlight group is Search
  new test/data/with-cabal/src/Foo.hs
  call cursor(4, 7)
  call s:write()
  bdelete

  " toggles
  new test/data/with-cabal/src/Foo.hs
  call cursor(4, 11)
  call s:write()
  call s:write()
  bdelete

  let g:ghcmod_type_highlight = 'WildMenu'
  new test/data/with-cabal/src/Foo.hs
  call cursor(4, 7)
  call s:write()
  bdelete
  unlet g:ghcmod_type_highlight

  " match changes on leaving windows
  new test/data/with-cabal/src/Foo.hs
  call cursor(4, 7)
  GhcModType
  let l:prev_id = b:ghcmod_type.match_id
  let l:prev_group = s:match_group(l:prev_id)
  let l:bufnr = bufnr('%')
  wincmd p
  let l:id = getbufvar(l:bufnr, 'ghcmod_type').match_id
  let l:group = s:match_group(l:prev_id)
  call add(s:outputs, join([l:prev_group, l:group, l:prev_id == l:id], ' '))
  wincmd p
  bdelete

  " clear
  new test/data/with-cabal/src/Foo.hs
  let l:prev_matches = getmatches()
  call cursor(4, 7)
  GhcModType
  let l:exist_ghcmod_type1 = exists('b:ghcmod_type')
  GhcModTypeClear
  let l:exist_ghcmod_type2 = exists('b:ghcmod_type')
  let l:matches = getmatches()
  call add(s:outputs, join([l:exist_ghcmod_type1, l:exist_ghcmod_type2, l:prev_matches == l:matches], ' '))
  bdelete

  call writefile(s:outputs, 'test/output/command_type.out')
endfunction

call s:main()
