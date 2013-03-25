let s:outputs = []

function! s:write()
  call add(s:outputs, ghcmod#detect_module())
endfunction

function! s:main()
  edit test/data/detect_module/Normal.hs
  call s:write()

  edit test/data/detect_module/NoModuleDecl.hs
  call s:write()

  edit test/data/detect_module/ModuleDeclInComment.hs
  call s:write()

  edit test/data/detect_module/ModuleWithSpace.hs
  call s:write()

  call writefile(s:outputs, 'test/output/detect_module.out')
endfunction

call s:main()
