" This function Wraps a value in a dict. DT stands
" for data type and 'wrapped' is the wrapped value,
" it's a list of values in fact.
function vlisp#dt#Wrap(ops, constructor, args) abort
  let d = { 'DT': a:constructor, 'wrapped': a:args }
  call extend(d, a:ops)

  function d.unwrap() dict
    if empty(self.wrapped)
      throw 'Unwrap empty error '.string(self)
    endif
    return self.wrapped
  endfunc

  function d.unwrap_or(v) dict
    return empty(self.wrapped) ? a:v : self.unwrap()
  endfunc

  function d.match(...) dict abort
    let args = vlisp#fp#ToPairs(a:000)
    for [ctr, Arm] in args
      if self.DT ==# ctr
        return call(Arm, self.wrapped)
      endif
    endfor
  endfunc

  return d
endfunc

" Receives a list of construtors as string and return
" a sumtype dict, with data construtors as mebmers of the
" dict.
function vlisp#dt#DT(ops, ...) abort
  " this is a dict, it let's me use foo.bar() syntax
  let d = {}

  " a:000 is all the function arguments
  for ctrs in a:000
    " desconstruct the list by head and tail, spliting
    " the by spaces.
    let [constructor; args] = split(ctrs, ' ')
    let args = join(args, ',')
    let Func = { ops, ctr -> { ... -> call(function('vlisp#dt#Wrap'), [ops, ctr, a:000]) } }(a:ops, constructor)
    let d[constructor] = Func
  endfor

  return d
endfunc
