" Evaluate a list
function s:eval_list(expr) abort
  if len(a:expr) == 0
    " Treat this is nil
    return a:expr
  else
    let [Car; cdr] = a:expr

    " Always evaluate car
    while s:is_redex(Car) " reducible expression
      let Car = s:eval(Car)
    endwhile

    if s:is_func(Car)
      return s:call_func(Car, cdr)
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

let s:deep = 0 " how nested we are in the expressions
               " used only for debugging
function s:eval(expr) abort
  let s:deep += 1
  let Result = 0
  if s:is_list(a:expr)
    let Result = s:eval_list(a:expr)
  else
    let Result = s:eval_atom(a:expr)
  endif

  let s:deep -= 1
  return Result
endfunc
" Search for item in list, item is a sym and list a list of args
" that are simple strings like ['a', 'b'] and sym are like ':a'
" ':b' etc
function s:in(item, list) abort
  return index(a:list, a:item) != -1
endfunc

function s:push_stackframe(item) abort
  if len(a:item) == 0
    return
  endif
  call insert(s:call_stack, a:item, 0)
endfunc

function s:pop_stackframe() abort
  if len(s:call_stack) > 0
    call remove(s:call_stack, 0)
  endif
endfunc

function s:free_vars(expr, bound_vars, free_vars) abort
  if s:is_list(a:expr)
    let alen = len(a:expr)

    " nil, just return
    if alen == 0
      return

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
  let lambda = {'type': 'lambda', 'args': a:args, 'body': a:body, 'scope': free_vars }
  for [k, v] in items(free_vars)
    if v ==# 'RECURSIVE_DEFINITION_SENTINEL'
      unlet free_vars[k]
    endif
  endfor
  return lambda
endfunc

function s:def_lazy(args, body) abort
  let free_vars = {}
  call s:free_vars(a:body, a:args, free_vars) " edits free_vars in place
  return {'type': 'lazy', 'args': a:args, 'body': a:body, 'scope': free_vars }
endfunc

function s:define(sym, body) abort
  if !s:is_defined(a:sym)
    let s:global_scope_user[a:sym] = s:eval(a:body)
  else
    throw 'Alredy defined symbol '.a:sym
  endif
endfunc

function s:defrec(sym, body) abort
  if !s:is_defined(a:sym)
    let s:global_scope_user[a:sym] = 'RECURSIVE_DEFINITION_SENTINEL'
    let s:global_scope_user[a:sym] = s:eval(a:body)
  else
    throw 'Alredy defined symbol '.a:sym
  endif
endfunc

function s:echo(msg) abort
  echo s:eval(a:msg)
endfunc

function s:trace(msg, arg) abort
  let result = s:eval(a:arg)
  echom 'Trace '.a:msg.' => '.string(result)
  return result
endfunc

function s:reduce(fn, args) abort
  let acc = s:eval(a:args[0])
  if len(a:args) > 1
    for item in a:args[1:]
      let acc = a:fn(acc, s:eval(item))
    endfor
  endif
  return acc
endfunc

function s:begin(...) abort
  if len(a:000) > 1
    for expr in a:000[:-2]
      call s:eval(expr)
    endfor
  endif
  return s:eval(a:000[-1])
endfunc

" This is the buitins, it's imutable
let s:global_scope = {
  \ ':=': {a, b -> s:eval(a) == s:eval(b)},
  \ ':!=': {a, b -> s:eval(a) != s:eval(b)},
  \ ':>': {a, b -> s:eval(a) > s:eval(b)},
  \ ':>=': {a, b -> s:eval(a) < s:eval(b)},
  \ ':<': {a, b -> s:eval(a) < s:eval(b)},
  \ ':<=': {a, b -> s:eval(a) < s:eval(b)},
  \ ':if': {c, a, b -> s:eval(c) ? s:eval(a) : s:eval(b) },
  \ ':eval': function('s:eval'),
  \ ':+': {... -> s:reduce({acc, arg -> s:eval(acc) + s:eval(arg)}, a:000)},
  \ ':-': {... -> s:reduce({acc, arg -> s:eval(acc) - s:eval(arg)}, a:000)},
  \ ':*': {... -> s:reduce({acc, arg -> s:eval(acc) * s:eval(arg)}, a:000)},
  \ ':/': {... -> s:reduce({acc, arg -> s:eval(arg) / s:eval(acc)}, a:000)},
  \ ':begin': function('s:begin'),
  \ ':lambda': function('s:def_lambda'),
  \ ':lazy': function('s:def_lazy'),
  \ ':define': function('s:define'),
  \ ':defrec': function('s:defrec'),
  \ ':echo': function('s:echo'),
  \ ':trace': function('s:trace'),
  \ }

" User defines
let s:global_scope_user = {}

" The call stack
let s:call_stack = []

" ((lambda (x) ...) 1) => { x: 1 }
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
endfunc

function s:call_lazy(lambda, args) abort
  let args = s:build_args(a:lambda.args, a:args)
  call s:push_stackframe(a:lambda.scope)
  call s:push_stackframe(args)
  let result = s:eval(a:lambda.body)
  call s:pop_stackframe()
  call s:pop_stackframe()
  return result
endfunc

function s:call_func(Func, args) abort
  return call(a:Func, a:args)
endfunc

function s:call_lambda(lambda, args) abort
  let eargs = map(a:args, {_, x -> s:eval(x)})
  let args = s:build_args(a:lambda.args, eargs)
  call s:push_stackframe(a:lambda.scope)
  call s:push_stackframe(args)
  let result = s:eval(a:lambda.body)
  call s:pop_stackframe()
  call s:pop_stackframe()
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
  for frame in s:call_stack
    if has_key(frame, a:sym)
      let result = frame[a:sym]
      return result
    endif
  endfor

  if has_key(s:global_scope_user, a:sym)
    return s:global_scope_user[a:sym]
  endif

  if has_key(s:global_scope, a:sym)
    return s:global_scope[a:sym]
  endif

  let symWithoutColon = a:sym[1:]
  try
    return function(symWithoutColon)
  catch /E700: Unknown function/
  catch /E129: Function name required/
  endtry

  if exists(symWithoutColon)
    try
      return eval(symWithoutColon)
    catch
    endtry
  endif

  throw 'Undefined symbol '.a:sym
endfunc

function s:is_defined(sym) abort
  try
    call s:lookup(a:sym)
    return v:true
  catch /^Undefined symbol/
    return v:false
  endtry
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

function vlisp#Eval(expr) abort
  return s:eval(a:expr)
endfunc

function vlisp#EvalMultiple(exprs) abort
  if len(a:exprs) > 1
    for expr in a:exprs[:-2]
      call s:eval(expr)
    endfor
  endif
  return s:eval(a:exprs[-1])
endfunc

function s:readallines(file) abort
  return join(readfile(a:file), "\n")
endfunc

function vlisp#LoadFile(file) abort
  return vlisp#LoadScript(s:readallines(a:file))
endfunc

function vlisp#LoadScript(string) abort
  let tree = parser#Parse(lex#All(a:string))
  return vlisp#EvalMultiple(tree)
endfunc

function vlisp#Reset() abort
  let s:call_stack = []
  let s:global_scope_user = {}
  let s:deep = 0
endfunc

command! -nargs=1 VLispLoad :call vlisp#LoadFile(<args>)
