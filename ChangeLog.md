# ChangeLog
## 0.4.0 (2013-03-13)
- Suppress empty line when `ghcmod#type()` fails
- Disable `:GhcModType` and `:GhcModTypeInsert` if the current buffer is modified
  - Add new variant `:GhcModType!` and `:GhcModTypeInsert!` which is executed even if the current buffer is modified.
  - Change `ghcmod#type()` and `ghcmod#type_insert()` to take an argument determining the behavior when the buffer is modified.
- Fix `ghcmod#detect_module()` to detect the module name more correctly
- Change the default directory to execute ghc-mod from (@drchaos)

## 0.3.0 (2013-03-06)
- Add `:GhcModTypeInsert` and `ghcmod#type_insert()` that inserts a type signature under the cursor (@johntyree)
- Add `:GhcModInfoPreview` that shows information in preview window (@johntyree)
- Make the parsing of check command more robust (@marcmo)
- Add buffer-local version of `g:ghcmod_ghc_options`

## 0.2.0 (2012-09-12)
- Fix the wrong comparison of versions in `ghcmod#check_version` (@yuttie)
- Fix `ghcmod#type()` on a program with compilation errors
- Add `g:ghcmod_use_basedir` option (@adimit)
- Add `:GhcModInfo [{identifier}]` command (@ajnsit)

## 0.1.2 (2012-06-04)
- Move ftplugin/haskell into after/ in order to co-exist with other ftplugins
- Fix `s:join_path()` for Windows

## 0.1.1 (2012-04-02)
- Fix the location of vimproc.vim

## 0.1.0 (2012-04-01)
- Initial release
