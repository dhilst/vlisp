func s:wrap(o)
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

function s:maybe()
  let d = {}

  func d.bind(f)
    return self.DT ==# 'just' ? a:f(self.v) : self
  endfunc

  return d
endfunc

function s:just(v)
  let d = s:wrap(a:v)
  let d.T = 'maybe'
  let d.DT = 'just'
  call extend(d, s:maybe())

  func d.map(f) dict
    let self.v = a:f(self.v)
    return self
  endfunc

  return d
endfunc

function s:nothing()
  let d = s:wrap(v:null)
  let d.T = 'maybe'
  let d.DT = 'nothing'
  let d.map = d.const
  call extend(d, s:maybe())

  func! d.unwrap()
    throw "Unwrap nothing!"
  endfunc

  return d
endfunc

function s:foldr(binop, start, list)
  if empty(a:list)
    return a:start
  endif
  return a:binop(a:list[0], s:foldr(a:binop, a:start, a:list[1:]))
endfunc

function s:list(...)
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

function s:dict(d)
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
