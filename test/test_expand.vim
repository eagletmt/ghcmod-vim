function! s:normalize(qflist)
  for l:qf in a:qflist
    if has_key(l:qf, 'filename')
      let l:qf.filename = fnamemodify(l:qf.filename, ':.')
    endif
  endfor
  return a:qflist
endfunction

function! s:make_qf_pred(qf)
  let l:pred = { 'qf': a:qf }
  function! l:pred.call(qf)
    for l:key in keys(self.qf)
      if !has_key(a:qf, l:key) || self.qf[l:key] != a:qf[l:key]
        return 0
      endif
    endfor
    return 1
  endfunction
  return l:pred
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_expand()
  edit test/data/th/Fuga.hs
  call self.assert.exist(':GhcModExpand')
  let l:qflist = ghcmod#expand(expand('%:p'))
  call s:normalize(l:qflist)
  let l:end_message = 'Splicing end here'
  let l:filename = 'test/data/th/Fuga.hs'
  call self.assert.any(s:make_qf_pred({ 'lnum': 6, 'col': 8, 'filename': l:filename }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 10, 'col': 2, 'filename': l:filename, 'text': l:end_message }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 8, 'filename': l:filename }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 31, 'filename': l:filename, 'text': l:end_message }), l:qflist)
endfunction

function! s:unit.test_expand_whitespace()
  edit test/data/th\ with\ whitespace/Fuga.hs
  call self.assert.exist(':GhcModExpand')
  let l:qflist = ghcmod#expand(expand('%:p'))
  call s:normalize(l:qflist)
  let l:end_message = 'Splicing end here'
  let l:filename = 'test/data/th with whitespace/Fuga.hs'
  call self.assert.any(s:make_qf_pred({ 'lnum': 6, 'col': 8, 'filename': l:filename }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 10, 'col': 2, 'filename': l:filename, 'text': l:end_message }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 8, 'filename': l:filename }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 31, 'filename': l:filename, 'text': l:end_message }), l:qflist)
endfunction

call s:unit.run()
