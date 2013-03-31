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
  let l:end_message = 'Splicing end here'
  call self.assert.any(s:make_qf_pred({ 'lnum': 6, 'col': 8 }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 10, 'col': 2, 'text': l:end_message }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 8 }), l:qflist)
  call self.assert.any(s:make_qf_pred({ 'lnum': 13, 'col': 31, 'text': l:end_message }), l:qflist)
endfunction

call s:unit.run()
