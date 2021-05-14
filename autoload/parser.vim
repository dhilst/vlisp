function s:pop(stack) abort
  return remove(a:stack, -1)
endfunc

function s:push(item, stack) abort
  call add(a:stack, a:item)
endfunc

function s:top(stack) abort
  return stack[-1]
endfunc

function s:in(el, list) abort
  return index(a:list, a:el) != -1
endfunc

function parser#Parse(tokens) abort
  let _buffer = ''
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
  return eval(_buffer)
endfunc


function parser#ParseAndEval(text) abort
  return vlisp#Eval(parser#Parse(lex#All(a:text)))
endfunc
