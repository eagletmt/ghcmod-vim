if exists('g:loaded_ghcmod') && g:loaded_ghcmod
  finish
endif
let g:loaded_ghcmod = 1

if !executable('ghc-mod')
  call ghcmod#print_error('ghcmod: ghc-mod is not executable!')
  finish
endif

let s:required_version = [1, 10, 6]
if !ghcmod#check_version(s:required_version)
  call ghcmod#print_error(printf('ghcmod: requires ghc-mod %s or higher', join(s:required_version, '.')))
  finish
endif

if !exists('g:ghcmod_type_highlight')
  let g:ghcmod_type_highlight = 'Search'
endif

command! -nargs=0 GhcModType echo ghcmod#type()[1]
command! -nargs=0 GhcModTypeClear call ghcmod#type_clear()
