# ghcmod.vim
Happy Haskell programming on Vim, powered by [ghc-mod](https://github.com/kazu-yamamoto/ghc-mod)

## Features

- Displaying the type of sub-expressions (`ghc-mod type`)
- Displaying error/warning messages and their locations (compiler plugins for `ghc-mod check` and `ghc-mod lint`)

Completions are supported by another plugin.
See [neco-ghc](https://github.com/ujihisa/neco-ghc) .

## Requirements

### vimproc
https://github.com/Shougo/vimproc

### ghc-mod
~~~sh
cabal install ghc-mod
~~~

## Details

### :GhcModType, :GhcModTypeClear
Type `:GhcModType` on a expression, then the sub-expression is highlighted and its type is echoed.
If you type `:GhcModType` multiple times, the sub-expression changes.

1. ![type1](http://cache.gyazo.com/361ad3652a412f780106ab07ad11f206.png)
2. ![type2](http://cache.gyazo.com/0c884849a971e367c75a6ba68bed0157.png)
3. ![type3](http://cache.gyazo.com/3644d66a3c5fbc51c01b5bb2053864cd.png)
4. ![type4](http://cache.gyazo.com/ece85e8a1250bebfd13208a63679a3db.png)
5. ![type5](http://cache.gyazo.com/71e4c79f9b42faaaf81b4e3695fb4d7f.png)

Type `:GhcModTypeClear` to clear sub-expression's highlight.

Sub-expressions are highlighted as `Search` by default.
You can customize it by setting `g:ghcmod_type_highlight` .

~~~vim
hi ghcmodType ctermbg=yellow
let g:ghcmod_type_highlight = 'ghcmodType'
~~~

### compiler plugins
Type `:compiler ghcmod_check` to use `ghc-mod check` as a compiler.
You can generate compiler errors/warnings by `:make` and they are available in quickfix window.

Similarly, type `:compiler ghcmod_lint` to use `ghc-mod lint` as a compiler.
