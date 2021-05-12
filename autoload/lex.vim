function lex#Lex(input, start, line) abort
  let input = a:input

  let [_, _, startpos] = matchstrpos(input, '\s*', a:start)

  let input = input[startpos:]

  if input[0] ==# '('
    return {
      \ 'type': 'LP',
      \ 'startpos': startpos,
      \ 'endpos': startpos + 1,
      \ 'line': a:line,
      \ }
  elseif input[0] ==# ')'
    return {
      \ 'type': 'RP',
      \ 'startpos': startpos,
      \ 'endpos': startpos + 1,
      \ 'line': a:line,
      \ }
  endif

  " Float
  let result = matchstr(input, '^\d\+\.\d\+')
  if !empty(result)
    return {
      \ 'type': 'float',
      \ 'value': str2float(result),
      \ 'startpos': startpos,
      \ 'endpos': startpos + len(result),
      \ 'line': a:line,
      \ }
  endif

  " Int
  let result = matchstr(input, '^\d\+')
  if !empty(result)
    return {
      \ 'type': 'int',
      \ 'value': str2float(result),
      \ 'startpos': startpos,
      \ 'endpos': startpos + len(result),
      \ 'line': a:line,
      \ }
  endif

  if input[0] ==# '"'
    return lex#ReadString(input, startpos, a:line)
  endif

  let result = matchstr(input, '^[^ ()]\+')
  if !empty(result)
    return {
      \ 'type': 'atom',
      \ 'value': result,
      \ 'startpos': startpos,
      \ 'endpos': startpos + len(result),
      \ 'line': a:line,
      \ }
  endif

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
