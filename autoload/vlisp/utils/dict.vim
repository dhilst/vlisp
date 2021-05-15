function vlisp#utils#dict#Add(dict, attr, val) abort
  let dict = copy(a:dict)
  let dict[a:attr] = a:val
  return dict
endfunc
