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

function! s:type()
  let [l:type] = s:capture('GhcModType')
  return [l:type, s:match_group(b:ghcmod_type.match_id)]
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_command_type()
  edit test/data/with-cabal/src/Foo.hs
  call cursor(4, 7)
  let [l:type, l:group] = s:type()
  call self.assert.equal(l:type, '[Char]')
  call self.assert.equal(l:group, 'Search')
endfunction

function! s:unit.test_command_type_toggle()
  edit test/data/with-cabal/src/Foo.hs
  call cursor(4, 11)
  let [l:type, _] = s:type()
  call self.assert.equal('[Char] -> [Char] -> [Char]', l:type)
  let [l:type, _] = s:type()
  call self.assert.equal('[Char]', l:type)
endfunction

function! s:unit.test_command_type_highlight()
  let g:ghcmod_type_highlight = 'WildMenu'
  try
    edit test/data/with-cabal/src/Foo.hs
    call cursor(4, 7)
    let [_, l:group] = s:type()
    call self.assert.equal('WildMenu', l:group)
  finally
    unlet g:ghcmod_type_highlight
  endtry
endfunction

function! s:unit.test_command_type_match_change()
  new test/data/with-cabal/src/Foo.hs
  call cursor(4, 7)
  silent GhcModType
  let l:prev_id = b:ghcmod_type.match_id
  let l:prev_group = s:match_group(l:prev_id)
  let l:bufnr = bufnr('%')
  wincmd p
  let l:id = getbufvar(l:bufnr, 'ghcmod_type').match_id
  let l:group = s:match_group(l:prev_id)
  wincmd p

  call self.assert.equal('Search', l:prev_group)
  call self.assert.equal('', l:group)
  call self.assert.not_equal(-1, l:prev_id)
  call self.assert.equal(-1, l:id)
endfunction

function! s:unit.test_command_type_clear()
  edit test/data/with-cabal/src/Foo.hs
  let l:prev_matches = getmatches()
  call cursor(4, 7)
  silent GhcModType
  call self.assert.exist('b:ghcmod_type')
  GhcModTypeClear
  call self.assert.not_exist('b:ghcmod_type')
  let l:matches = getmatches()
  call self.assert.equal(l:prev_matches, l:matches)
endfunction

call s:unit.run()
