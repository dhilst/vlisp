function vlisp#utils#list#Add(list, val) abort
  let list = copy(a:list)
  call add(list, a:val)
  return list
endfunc
