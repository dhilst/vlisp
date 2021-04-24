function s:sum(...) abort
  let r = 0
  for i in a:000
    let i = s:eval(i)
    let r = r + i
  endfor
  return r
endfun

" Search for item in list, item is a sym and list a list of args
" that are simple strings like ['a', 'b'] and sym are like ':a'
" ':b' etc
function s:in(item, list) abort
  return index(a:list, a:item[1:]) != -1
endfun

function s:push_scope(item) abort
  call add(s:scopes, a:item)
endfun

function s:pop_scope() abort
  return remove(s:scopes, -1)
endfun

function s:local_scope(args, body, scope) abort
  if s:is_list(a:body)
    for element in a:body
      call s:local_scope(a:args, element, a:scope)
    endfor
  elseif s:is_sym(a:body) && !s:in(a:body, a:args) && !s:in(a:body, keys(s:global_scope))
   " not a bound variable, global are always available so they are not copied
    let a:scope[a:body] = s:lookup(a:body)
  endif
endfun

function s:def_lambda(args, body) abort
  let scope = {}
  call s:local_scope(a:args, a:body, scope) " edits scope in place
  return {'type': 'lambda', 'args': a:args, 'body': a:body, 'scope': scope }
endfun

function s:def_module(modname, body) abort
  if !has_key(s:modules, a:modname)
    let s:current_module = a:modname
    let s:modules[a:modname] = s:eval(a:body)
  endif
  return s:modules[a:modname]
endfun

" This is the global scope
let s:global_scope = {
  \ '>': {a, b -> a > b},
  \ 'if': {c, a, b ->  s:eval(c) ? s:eval(a) : s:eval(b) },
  \ 'eval': {e -> s:eval(e)},
  \ '+': function('s:sum'),
  \ 'lambda': function('s:def_lambda'),
  \ 'module': function('s:def_module'),
  \ }

let s:current_module = v:false
let s:modules = {}

" This is the local scope stacked, the inner scope goes first
" and outer scope goes last. A scope is a dictionary where symbols
" point to values. Scopes are stacked in the lookup order, i.e, inner
" scopes goes first.
let s:scopes = []

" Build args scope, to be pushed to s:scopes
function s:build_args(argnames, argvalues)
  let args = {}
  let i = 0
  let max = len(a:argvalues)
  while i < max
    let args[a:argnames[i]] = a:argvalues[i]
    let i += 1
  endwhile
  return args
endfun

function s:call_lambda(lambda, args) abort
  let args = s:build_args(a:lambda.args, a:args)
  call s:push_scope(a:lambda.scope)
  call s:push_scope(args)
  let result = s:eval(a:lambda.body)
  call s:pop_scope()
  call s:pop_scope()
  return result
endfun

function s:is_sym(expr) abort
  return type(a:expr) == v:t_string && a:expr[0] ==# ':'
endfun

function s:is_func(expr) abort
  return type(a:expr) == v:t_func
endfun

function s:is_lambda(expr) abort
  return type(a:expr) == v:t_dict && a:expr.type ==# 'lambda'
endfun

function s:is_list(expr) abort
  return type(a:expr) == v:t_list
endfun

function s:lookup(sym) abort
  let sym = a:sym[1:]
  for scope in s:scopes
    if has_key(scope, sym)
      return scope[sym]
    endif
  endfor

  if has_key(s:global_scope, sym)
    return s:global_scope[sym]
  endif

  throw 'Undefined symbol '.a:sym
endfun

function s:is_redex(car) abort
  if s:is_sym(a:car)
    return v:true
  elseif s:is_list(a:car)
    return s:is_redex(a:car[0])
  else
    return v:false
  endif
endfun

" Evaluate a list
function s:eval_list(expr) abort
  if len(a:expr) == 0
    " Treat this is nil
    return a:expr
  else
    let [Car; cdr] = a:expr

    " Always evaluate car
    while s:is_redex(Car)
      let Car = s:eval(Car)
    endwhile

    if s:is_func(Car)
      return call(Car, cdr)
    elseif s:is_lambda(Car)
      return s:call_lambda(Car, cdr)
    else
      return a:expr
    endif
  endif
endfun

function s:eval_atom(expr) abort
  if s:is_sym(a:expr)
    return s:lookup(a:expr)
  endif
  return a:expr
endfun

function s:eval(expr) abort
  if s:is_list(a:expr)
    return s:eval_list(a:expr)
  else
    return s:eval_atom(a:expr)
  endif
endfun

function vlisp#Eval(expr) abort
  return s:eval(a:expr)
endfun
