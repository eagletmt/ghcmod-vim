if exists('current_compiler')
  finish
endif
let current_compiler = 'ghcmod_lint'

let &l:makeprg = 'ghc-mod lint %'
let &l:errorformat = join([
      \ '%f:%l:%c: %tarning: %m',
      \ '%f:%l:%c:%m',
      \ ], ',')
