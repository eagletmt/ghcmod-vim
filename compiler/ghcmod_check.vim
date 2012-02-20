if exists('current_compiler')
  finish
endif
let current_compiler = 'ghcmod_check'

let &l:makeprg = 'ghc-mod check %:p:t'
let &l:errorformat = join([
      \ '%f:%l:%c:%tarning: %m',
      \ '%f:%l:%c:%m',
      \ ], ',')

" XXX: `ghc-mod check` produces only filename.
" These autocmds can deal with it, but could conflict with other plugins.
augroup ghcmod
  autocmd! * <buffer>
  autocmd QuickFixCmdPre <buffer> lcd `=expand('%:p:h')`
  autocmd QuickFixCmdPost <buffer> lcd -
augroup END
