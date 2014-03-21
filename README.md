# ghcmod.vim
[![Build Status](https://api.travis-ci.org/eagletmt/ghcmod-vim.svg)](https://travis-ci.org/eagletmt/ghcmod-vim)
[![Gitter chat](https://badges.gitter.im/eagletmt/ghcmod-vim.png)](https://gitter.im/eagletmt/ghcmod-vim)

Happy Haskell programming on Vim, powered by [ghc-mod](https://github.com/kazu-yamamoto/ghc-mod)

- [http://www.vim.org/scripts/script.php?script\_id=4473](http://www.vim.org/scripts/script.php?script_id=4473)
- https://github.com/eagletmt/ghcmod-vim/releases

## Features

- Displaying the type of sub-expressions (`ghc-mod type`)
- Displaying error/warning messages and their locations (`ghc-mod check` and `ghc-mod lint`)
- Displaying the expansion of splices (`ghc-mod expand`)

Completions are supported by another plugin.
See [neco-ghc](https://github.com/eagletmt/neco-ghc) .

## Requirements

### Vim
ghcmod.vim contains ftplugin.
Please make sure that filetype plugin is enabled.
To check it, type `:filetype` and you would see something like this: `filetype detection:ON  plugin:ON  indent:ON`.
You can enable it by `:filetype plugin on`.
I highly recommend adding `filetype plugin indent on` to your vimrc.
See `:help :filetype-overview` for more details.

### vimproc
https://github.com/Shougo/vimproc

### ghc-mod >= 2.1.2
```sh
cabal install ghc-mod
```

## Details
If you'd like to give GHC options, set `g:ghcmod_ghc_options`.

```vim
let g:ghcmod_ghc_options = ['-idir1', '-idir2']
```

Also, there's buffer-local version `b:ghcmod_ghc_options`.

```vim
autocmd BufRead,BufNewFile ~/.xmonad/* call s:add_xmonad_path()
function! s:add_xmonad_path()
  if !exists('b:ghcmod_ghc_options')
    let b:ghcmod_ghc_options = []
  endif
  call add(b:ghcmod_ghc_options, '-i' . expand('~/.xmonad/lib'))
endfunction
```

### :GhcModType, :GhcModTypeClear
Type `:GhcModType` on a expression, then the sub-expression is highlighted and its type is echoed.
If you type `:GhcModType` multiple times, the sub-expression changes.

1. ![type1](http://cache.gyazo.com/361ad3652a412f780106ab07ad11f206.png)
2. ![type2](http://cache.gyazo.com/0c884849a971e367c75a6ba68bed0157.png)
3. ![type3](http://cache.gyazo.com/3644d66a3c5fbc51c01b5bb2053864cd.png)
4. ![type4](http://cache.gyazo.com/ece85e8a1250bebfd13208a63679a3db.png)
5. ![type5](http://cache.gyazo.com/71e4c79f9b42faaaf81b4e3695fb4d7f.png)

Since ghc-mod 1.10.8, not only sub-expressions but name bindings and sub-patterns are supported.

- ![type-bind](http://cache.gyazo.com/cee203adbf715f00d2dbd82c5cff3eaa.png)
- ![type-pat](http://cache.gyazo.com/7a22068b73442e8447a4081d5ddffd31.png)

Type `:GhcModTypeClear` to clear sub-expression's highlight.

Sub-expressions are highlighted as `Search` by default.
You can customize it by setting `g:ghcmod_type_highlight` .

```vim
hi ghcmodType ctermbg=yellow
let g:ghcmod_type_highlight = 'ghcmodType'
```

### :GhcModCheck, :GhcModLint
You can get compiler errors/warnings by `:GhcModCheck` and they are available in quickfix window.

![check](http://cache.gyazo.com/c09399b2fe370ce9d328b8ed12118de8.png)

Similarly, type `:GhcModLint` to get suggestions by `ghc-mod lint`.

If you'd like to pass options to hlint, set `g:ghcmod_hlint_options`.

```vim
let g:ghcmod_hlint_options = ['--ignore=Redundant $']
```

![lint](http://cache.gyazo.com/3b64724ce2587e03761fe618457f1c2e.png)

If you'd like to open in another way the quickfix, set `g:ghcmod_open_quickfix_function`.

```vim
let g:ghcmod_open_quickfix_function = 'GhcModQuickFix'
function! GhcModQuickFix()
  " for unite.vim and unite-quickfix
  :Unite -no-empty quickfix

  " for ctrlp
  ":CtrlPQuickfix

  " for FuzzyFinder
  ":FufQuickfix
endfunction
```

### :GhcModCheckAsync, :GhcModLintAsync, :GhcModCheckAndLintAsync
You can run check and/or lint asynchronously.

This would be useful when you'd like to run check and/or lint automatically (especially on `BufWritePost`).
See Customize wiki page for more detail.

### :GhcModExpand
You can see the expansion of splices by `:GhcModExpand` and they are available in quickfix window.

![expand](http://cache.gyazo.com/bcbee2b84f956a87b636a67b5d5af488.png)

This feature was introduced since ghc-mod 1.10.10.

## Customize
See wiki page [Customize](https://github.com/eagletmt/ghcmod-vim/wiki/Customize).

## License
[BSD3 License](http://www.opensource.org/licenses/BSD-3-Clause), the same license as ghc-mod.

Copyright (c) 2012-2013, eagletmt
