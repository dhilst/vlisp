function lex#Lex(text, start) abort
  let [result, startpos, endpos] = matchstrpos(a:text, '\S\+', a:start)

  if startpos == -1
    throw 'syntax error, empty match'
  elseif match(result, '^\d\+\.\d\+$') != -1
    return {
      \ 'type': 'float',
      \ 'value': str2float(result),
      \ 'startpos': startpos,
      \ 'endpos': endpos,
      \ }
  elseif match(result, '^\d\+$') != -1
    return {
      \ 'type': 'int',
      \ 'value': str2nr(result),
      \ 'startpos': startpos,
      \ 'endpos': endpos,
      \ }
  elseif result[0] ==# '"'
    let [result, startpos, endpos] = matchstrpos(a:text, '".*"', startpos)
    if startpos != -1
      return {
        \ 'type': 'string',
        \ 'value': result,
        \ 'startpos': startpos,
        \ 'endpos': endpos,
        \ }
    else
      throw 'syntax error, invalid string'
    endif
  else
    return {
      \ 'type': 'atom',
      \ 'value': result,
      \ 'startpos': startpos,
      \ 'endpos': endpos,
      \ }
  endif
endfunc
