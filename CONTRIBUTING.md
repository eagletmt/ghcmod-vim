# Contributing

## Issues
When submitting an issue, please include the output by `:GhcModDiagnosis`.

```vim
GhcModDiagnosis
```

It shows your environment information possibly related to ghcmod.vim.

- Current filetype
    - ghcmod.vim only works in the buffer with filetype haskell.
- Filetype status
    - ghcmod.vim is a ftplugin. See `:help filetype-overview` and `:help filetype-plugins`.
- ghc-mod executable
    - ghcmod.vim requires [ghc-mod](https://github.com/kazu-yamamoto/ghc-mod) and it must be placed in your `$PATH`.
- vimproc.vim
    - ghcmod.vim requires [vimproc.vim](https://github.com/Shougo/vimproc.vim).
- ghc-mod version
