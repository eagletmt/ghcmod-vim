let s:unit = tinytest#new()

function! s:unit.test_command_sig_function()
  edit test/data/sig/SigFunction.hs
  call cursor(3, 1)
  GhcModSigCodegen
  call self.assert.match('^func x y f = ', getline(line('.')+1))
endfunction

function! s:unit.test_command_sig_instance()
  edit test/data/sig/SigInstance.hs
  call cursor(9, 1)
  GhcModSigCodegen
  call self.assert.match('^\s*cInt x = ', getline(line('.')+1))
  call self.assert.match('^\s*cString x = ', getline(line('.')+2))
endfunction

function! s:unit.teardown()
  " Discard changes
  bdelete!
endfunction

call s:unit.run()
