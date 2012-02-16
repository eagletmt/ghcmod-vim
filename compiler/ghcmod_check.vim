if exists('current_compiler')
  finish
endif
let current_compiler = 'ghcmod_check'

let &l:makeprg = 'ghc-mod check %'
let &l:errorformat = join([
      \ '%f:%l:%c:%tarning: %m',
      \ '%f:%l:%c:%m',
      \ ], ',')
