# ChangeLog
## x.x.x (xxxx-xx-xx)
- Add `:GhcModDiagnostics` command

## 1.2.0 (2014-02-02)
- Support Cabal sandbox (@andy-morris, #33)
- Support lhaskell (@carlohamalainen, #36)
- Add another way to open the quickfix (@shiena, #37)
- Workaround `ghcmod#util#is_abspath()` on Windows with Vim < 7.4.001 (@Grivr, #41)

## 1.1.0 (2013-10-16)
- Specify line separator by "-b" option (@preygel, #32)
    - This requires ghc-mod >= 2.1.2

## 1.0.0 (2013-04-25)
- Refactor many autoload functions
    - ghcmod.vim is an interface to ghc-mod
    - ghcmod/command.vim contains definitions of commands
    - ghcmod/type.vim is an implementation of `:GhcModType`
        - Now `w:ghcmod_type_matchid` is not needed and deleted
    - ghcmod/util.vim is a collection of utilities
- Add test cases
- Speed up boot time by moving autoload functions used at loading ftplugins
- Add commands with `!` that is executed even if the current buffer is modified
- Show splicing end locations in `:GhcModExpand`
- Fix escaping in `:GhcModInfoPreview`
- Fix ignorance of `g:ghcmod_ghc_options`

## 0.4.0 (2013-03-13)
- Suppress empty line when `ghcmod#type()` fails
- Disable `:GhcModType` and `:GhcModTypeInsert` if the current buffer is modified
    - Add new variant `:GhcModType!` and `:GhcModTypeInsert!` which is executed even if the current buffer is modified.
    - Change `ghcmod#type()` and `ghcmod#type_insert()` to take an argument determining the behavior when the buffer is modified.
- Fix `ghcmod#detect_module()` to detect the module name more correctly
- Change the default directory to execute ghc-mod from (@drchaos, #25)

## 0.3.0 (2013-03-06)
- Add `:GhcModTypeInsert` and `ghcmod#type_insert()` that inserts a type signature under the cursor (@johntyree, #15)
- Add `:GhcModInfoPreview` that shows information in preview window (@johntyree, #15)
- Make the parsing of check command more robust (@marcmo, #21)
- Add buffer-local version of `g:ghcmod_ghc_options`

## 0.2.0 (2012-09-12)
- Fix the wrong comparison of versions in `ghcmod#check_version` (@yuttie, #11)
- Fix `ghcmod#type()` on a program with compilation errors
- Add `g:ghcmod_use_basedir` option (@adimit, #12)
- Add `:GhcModInfo [{identifier}]` command (@ajnsit, #14)

## 0.1.2 (2012-06-04)
- Move ftplugin/haskell into after/ in order to co-exist with other ftplugins
- Fix `s:join_path()` for Windows

## 0.1.1 (2012-04-02)
- Fix the location of vimproc.vim

## 0.1.0 (2012-04-01)
- Initial release
