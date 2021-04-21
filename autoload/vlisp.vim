function s:sum(...) abort
  let r = 0
  for i in a:000
    let i = s:eval(i)
    let r = r + i
  endfor
  return r
endfunc

function s:def_lambda(args, body) abort
  return {'type': 'lambda', 'args': a:args, 'body': a:body, 'environ': deepcopy(s:environ) }
endfunc

" This is the global scope
let s:global_env = {
      \ '>': {a, b -> a > b},
      \ 'if': {c, a, b ->  s:eval(c) ? s:eval(a) : s:eval(b) },
      \ 'eval': {e -> s:eval(e)},
      \ '+': function('s:sum'),
      \ 'lambda': function('s:def_lambda'),
      \ }

" This is the local scope stacked, the inner scope goes first
" and outer scope goes last.
let s:environ = []

function s:build_args(argnames, argvalues)
  let args = {}
  let i = 0
  let max = len(a:argvalues)
  while i < max
    let args[a:argnames[i]] = a:argvalues[i]
    let i += 1
  endwhile
  return args
endfunc

function s:call_lambda(lambda, args) abort
  echom 'calling lambda'.string(a:lambda).' '.string(a:args).' '.string(localtime())
  let environ_bkp = copy(s:environ)
  let args = s:build_args(a:lambda.args, a:args)
  call extend(s:environ, a:lambda.environ)
  call insert(s:environ, args)
  echom 'calling lambda with environ = '.string(s:environ)
  let result = s:eval(a:lambda.body)
  let s:environ = environ_bkp
  echom 'lambda called'
  return result
endfunc


function s:is_sym(expr) abort
  return type(a:expr) == v:t_string && a:expr[0] ==# ':'
endfun

function s:is_func(expr) abort
  return type(a:expr) == v:t_func
endfunc

function s:is_lambda(expr) abort
  return type(a:expr) == v:t_dict && a:expr.type ==# 'lambda'
endfunc

function s:is_list(expr) abort
  return type(a:expr) == v:t_list
endfunc

function s:lookup(sym) abort
  let sym = a:sym[1:]
  echom 'looking up for '.sym.' with environ '.string(s:environ)
  for scope in s:environ
    if has_key(scope, sym)
      return scope[sym]
    endif
  endfor

  if has_key(s:global_env, sym)
    return s:global_env[sym]
  endif

  throw 'Undefined symbol '.a:sym
endfun

" Evaluate a list
function s:eval_list(expr) abort
  if len(a:expr) == 0
    " Treat this is nil
    return a:expr
  else
    let [Car; cdr] = a:expr

    if s:is_sym(Car)
      let Car = s:lookup(Car)
    endif

    if s:is_func(Car)
      " Evaluate the arguments
      " map(cdr, {arg -> vlisp#Eval(arg, )})
      return call(Car, cdr)
    elseif s:is_list(Car)
      return s:eval([s:eval(Car)] + cdr)
    elseif s:is_lambda(Car)
      return s:call_lambda(Car, cdr)
    else
      " Not callable, just return it
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
  echom 'evaluating '.string(a:expr)
  if s:is_list(a:expr)
    return s:eval_list(a:expr)
  else
    return s:eval_atom(a:expr)
  endif
endfun

function vlisp#Eval(expr) abort
  return s:eval(a:expr)
endfun
