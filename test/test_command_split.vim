let s:unit = tinytest#new()

function! s:unit.test_command_split()
  edit test/data/split/Split.hs
  call cursor(4, 3)
  GhcModSplitFunCase
  " Don't move cursor line
  call self.assert.equal(line('.'), 4)
  call self.assert.equal(getline('.'), 'f [] = undefined')
  call self.assert.equal(getline(line('.')+1), 'f (x:xs) = undefined')
endfunction

function! s:unit.teardown()
  " Discard changes
  bdelete!
endfunction

call s:unit.run()
