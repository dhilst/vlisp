func vlisp#fp#Wrap(o)
  let d = {'v': a:o}

  function d.unwrap() dict
    return self.v
  endfunc

  function d.unwrap_or(v) dict
    return self.v == v:null ? a:v : self.v
  endfunc

  function d.const(_) dict
    return self
  endfunc

  return d
endfunc

function s:foldr(binop, start, list)
  if empty(a:list)
    return a:start
  endif
  return a:binop(a:list[0], s:foldr(a:binop, a:start, a:list[1:]))
endfunc

function vlisp#fp#List(...)
  let d = s:wrap(a:000)

  function d.prepend(v) dict
    let cpy = deepcopy(self)
    echo "cpy.v => ".string(cpy.v)
    call insert(cpy.v, a:v)
    return cpy
  endfunc

  function d.append(v) dict
    let cpy = deepcopy(self)
    call add(cpy.v, a:v)
    return cpy
  endfunc

  function d.map(f) dict
    let cpy = deepcopy(self)
    let cpy.v = map(cpy.v, {_, x -> a:f(x)})
    return cpy
  endfunc

  function d.foldr(binop, start) dict
    let cpy = deepcopy(self)
    let cpy.v = s:foldr(a:binop, a:start, cpy.v)
    return cpy
  endfunc

  return d
endfunc

function vlisp#fp#Dict(d)
  let d = s:wrap(a:d)

  function d.add(k, v) dict
    let cpy = deepcopy(self)
    let cpy.v[a:k] = a:v
    return cpy
  endfunc

  function d.del(k) dict
    let cpy = deepcopy(self)
    unlet cpy.v[k]
    return cpy
  endfunc

  function d.map(f) dict
    let cpy = deepcopy(self)
    let cpy.v = map(cpy.v, a:f)
    return cpy
  endfunc

  return d
endfunc

function vlisp#fp#Zip(a1, a2) abort
  let result = []
  let length = min([len(a:a1), len(a:a2)])
  let i = 0
  while i < length
    call add(result, [a:a1[i], a:a2[i]])
    let i += 1
  endwhile
  return result
endfunction

function vlisp#fp#Sublist(a, ...) abort
  let result = []
  let start_ = len(a:000) >= 1 ? a:000[0] : 0
  let step = len(a:000) >= 2 ? a:000[1] : 1
  let end_ = len(a:000) >= 3 ? a:000[2] : len(a:a)
  let end_ = end_ < 0 ? len(a:a) - end_ : end_
  let i = start_
  while i < end_
    call add(result, a:a[i])
    let i += step
  endwhile
  return result
endfunc

function vlisp#fp#ToPairs(a) abort
  let a1 = vlisp#fp#Sublist(a:a, 0, 2)
  let a2 = vlisp#fp#Sublist(a:a, 1, 2)
  return vlisp#fp#Zip(a1, a2)
endfunction

function s:maybeOps()
  let d = {}

  function d.map(f) self
    self.match('just', {x -> d.
  endfunc
endfunc
