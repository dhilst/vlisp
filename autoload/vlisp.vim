function s:sum(...) abort
  let r = 0
  for i in a:000
    let i = s:eval(i)
    let r = r + i
  endfor
  return r
endfunc

" Search for item in list, item is a sym and list a list of args
" that are simple strings like ['a', 'b'] and sym are like ':a'
" ':b' etc
function s:in(item, list) abort
  return index(a:list, a:item) != -1
endfunc

function s:push_scope(item) abort
  call add(s:scopes, a:item)
endfunc

function s:pop_scope() abort
  return remove(s:scopes, -1)
endfunc

function s:free_vars(expr, bound_vars, free_vars) abort
  if s:is_list(a:expr)
    let alen = len(a:expr)

    " nil, just return
    if alen == 0
      return;

    " unary list, lookup inside it
    elseif alen == 1
      call s:free_vars(a:expr[0], a:bound_vars, a:free_vars)

    " Has at last car and cdr
    else
      let [car; cdr] = a:expr
      if car ==# ':lambda' || car ==# ':lazy'
        let [args_, body] = cdr
        call extend(a:bound_vars, args_)
        call s:free_vars(body, a:bound_vars, a:free_vars)
      else
        for element in a:expr
          call s:free_vars(element, a:bound_vars, a:free_vars)
        endfor
      endif
    endif
  elseif s:is_sym(a:expr)
    if !s:in(a:expr, a:bound_vars) && !s:in(a:expr, keys(s:global_scope))
      let a:free_vars[a:expr] = s:lookup(a:expr)
    endif
  endif
endfunc

function s:def_lambda(args, body) abort
  let free_vars = {}
  call s:free_vars(a:body, a:args, free_vars) " edits free_vars in place
  return {'type': 'lambda', 'args': a:args, 'body': a:body, 'scope': free_vars }
endfunc

function s:def_lazy(args, body) abort
  let free_vars = {}
  call s:free_vars(a:body, a:args, free_vars) " edits free_vars in place
  return {'type': 'lazy', 'args': a:args, 'body': a:body, 'scope': free_vars }
endfunc

function s:define(sym, body) abort
  call s:push_scope({ a:sym: a:body })
endfunc

" This is the global scope
let s:global_scope = {
  \ ':>': {a, b -> a > b},
  \ ':if': {c, a, b ->  s:eval(c) ? s:eval(a) : s:eval(b) },
  \ ':eval': function('s:eval'),
  \ ':+': function('s:sum'),
  \ ':lambda': function('s:def_lambda'),
  \ ':lazy': function('s:def_lazy'),
  \ ':define': function('s:define'),
  \ }

let s:current_module = v:false
let s:modules = {}

" This is the local scope stacked, the inner scope goes first
" and outer scope goes last. A scope is a dictionary where symbols
" point to values. Scopes are stacked in the lookup order, i.e, inner
" scopes goes first.
let s:scopes = []

" ((lambda (x) ...) 1) => { x: 1 }
" Build args scope, to be pushed to s:scopes
function s:build_args_lazy(argnames, argvalues)
  let args = {}
  let i = 0
  let max = len(a:argvalues)
  while i < max
    let args[a:argnames[i]] = a:argvalues[i]
    let i += 1
  endwhile
  return args
endfunc

function s:build_args_strict(argnames, argvalues)
  let args = {}
  let i = 0
  let max = len(a:argvalues)
  while i < max
    let args[a:argnames[i]] = s:eval(a:argvalues[i])
    let i += 1
  endwhile
  return args
endfunc

function s:call_lazy(lambda, args) abort
  let args = s:build_args_lazy(a:lambda.args, a:args)
  call s:push_scope(a:lambda.scope)
  call s:push_scope(args)
  let result = s:eval(a:lambda.body)
  call s:pop_scope()
  call s:pop_scope()
  return result
endfunc

function s:call_lambda(lambda, args) abort
  let args = s:build_args_strict(a:lambda.args, a:args)
  call s:push_scope(a:lambda.scope)
  call s:push_scope(args)
  "let args = map(a:args, {e -> s:eval(e)})
  let result = s:eval(a:lambda.body)
  call s:pop_scope()
  call s:pop_scope()
  return result
endfunc

function s:is_sym(expr) abort
  return type(a:expr) == v:t_string && a:expr[0] ==# ':'
endfunc

function s:is_func(expr) abort
  return type(a:expr) == v:t_func
endfunc

function s:is_lambda(expr) abort
  return type(a:expr) == v:t_dict && a:expr.type ==# 'lambda'
endfunc

function s:is_lazy(expr) abort
  return type(a:expr) == v:t_dict && a:expr.type ==# 'lazy'
endfunc

function s:is_list(expr) abort
  return type(a:expr) == v:t_list
endfunc

function s:lookup(sym) abort
  for scope in s:scopes
    if has_key(scope, a:sym)
      let result = scope[a:sym]
      return result
    endif
  endfor

  if has_key(s:global_scope, a:sym)
    return s:global_scope[a:sym]
  endif

  throw 'Undefined symbol '.a:sym
endfunc

function s:is_redex(car) abort
  if s:is_sym(a:car)
    return v:true
  elseif s:is_list(a:car)
    return s:is_redex(a:car[0])
  else
    return v:false
  endif
endfunc

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
    elseif s:is_lazy(Car)
      return s:call_lazy(Car, cdr)
    elseif s:is_lambda(Car)
      return s:call_lambda(Car, cdr)
    else
      return a:expr
    endif
  endif
endfunc

function s:eval_atom(expr) abort
  if s:is_sym(a:expr)
    return s:lookup(a:expr)
  endif
  return a:expr
endfunc

function s:eval(expr) abort
  if s:is_list(a:expr)
    return s:eval_list(a:expr)
  else
    return s:eval_atom(a:expr)
  endif
endfunc

function vlisp#Eval(expr) abort
  return s:eval(a:expr)
endfunc
