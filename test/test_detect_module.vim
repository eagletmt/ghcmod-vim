let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_normal()
  edit test/data/detect_module/Normal.hs
  call self.assert.equal('Normal', ghcmod#detect_module())
endfunction

function! s:unit.test_no_module_decl()
  edit test/data/detect_module/NoModuleDecl.hs
  call self.assert.equal('Main', ghcmod#detect_module())
endfunction

function! s:unit.test_module_decl_in_comment()
  edit test/data/detect_module/ModuleDeclInComment.hs
  call self.assert.equal('ActualModule', ghcmod#detect_module())
endfunction

function! s:unit.test_module_with_space()
  edit test/data/detect_module/ModuleWithSpace.hs
  call self.assert.equal('ModuleWithSpace', ghcmod#detect_module())
endfunction

call s:unit.run()
