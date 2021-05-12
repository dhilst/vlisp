function lex#IgnoreWhitespace(input, start, line) abort
  let i = a:start
  let line = a:line

  while v:true
    if a:input[i] ==# ' ' || a:input[i] ==# "\t"
      let i += 1
    elseif a:input[i] ==# "\n"
      let line += 1
    else
      break
    endif
  endwhile

  return [i, line]
endfunc

function lex#Lex(input, start, line) abort
  let [startpos, line] = lex#IgnoreWhitespace(a:input, a:start, a:line)

  if a:input[startpos] ==# '('
    return {
      \ 'type': 'LP',
      \ 'startpos': startpos,
      \ 'endpos': startpos + 1,
      \ 'line': line,
      \ }
  elseif a:input[startpos] ==# ')'
    return {
      \ 'type': 'RP',
      \ 'startpos': startpos,
      \ 'endpos': startpos + 1,
      \ 'line': line,
      \ }
  endif

  " Float
  let result = matchstr(a:input[startpos:], '^\d\+\.\d\+')
  if !empty(result)
    return {
      \ 'type': 'float',
      \ 'value': str2float(result),
      \ 'startpos': startpos,
      \ 'endpos': startpos + len(result),
      \ 'line': line,
      \ }
  endif

  " Int
  let result = matchstr(a:input[startpos:], '^\d\+')
  if !empty(result)
    return {
      \ 'type': 'int',
      \ 'value': str2float(result),
      \ 'startpos': startpos,
      \ 'endpos': startpos + len(result),
      \ 'line': line,
      \ }
  endif

  if a:input[0] ==# '"'
    return lex#ReadString(a:input, startpos, a:line)
  endif

  "let result = matchstr(input, '^[^ ()]\+')
  return lex#ReadAtom(a:input, startpos, a:line)
endfunc


function lex#ReadAtom(input, startpos, line)
  echom "input ".a:input
  let i = a:startpos
  let inputLength = len(a:input)
  let line = a:line

  while v:true
    if a:input[i] ==# " " || a:input[i] ==# "(" || a:input[i] ==# ")" || a:input ==# "\n" || a:input ==# "\t" || i >= inputLength
      echom 'startpos '.a:startpos
      return {
        \ 'type': 'atom',
        \ 'value': a:input[a:startpos : i],
        \ 'startpos': a:startpos,
        \ 'endpos': i,
        \ 'line': line
        \ }
    else
      let i += 1
    endif
  endwhile
endfunc

function lex#ReadString(input, startpos, line)
  let i = 1
  let l = len(a:input)
  let escaping = v:false

  while v:true
    if i > l
      throw 'syntax error, EOF while expecting "'
    endif

    if a:input[i] ==# '"' && !escaping
      return {
            \ 'type': 'string',
            \ 'value': a:input[0:i+1],
            \ 'startpos': a:startpos,
            \ 'endpos': i,
            \ 'line': a:line,
            \ }
    endif
    let scaping = a:input[i] ==# '\'
    let i += 1
  endwhile
endfunc
