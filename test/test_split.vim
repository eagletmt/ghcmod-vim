let s:unit = tinytest#new()

function! s:unit.test_split()
  edit test/data/split/Split.hs
  let l:decls = ghcmod#split(4, 3, expand('%:p'), 'Split')
  call self.assert.equal(['f [] = undefined', 'f (x:xs) = undefined'], l:decls)
endfunction

call s:unit.run()
