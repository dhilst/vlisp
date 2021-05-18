function s:in(el, list) abort
  return index(a:list, a:el) != -1
endfunc

function parser#Parse(tokens) abort
  let _buffer = '['
  for token in a:tokens
    if len(_buffer) > 1 && _buffer[-1:-1] !=# '['
      let _buffer .= ', '
    endif

    if s:in(token.type, ['int', 'float'])
      let _buffer .= token.value
    elseif token.type ==# 'string'
      let _buffer .= "'".token.value."'"
    elseif token.type ==# 'sym'
      let _buffer .= "'".token.value."'"
    elseif token.type ==# 'LP'
      let _buffer .= '['
    elseif token.type ==# 'RP'
      let _buffer .= ']'
    endif
  endfor

  let _buffer .= ']'
  return eval(_buffer)
endfunc
