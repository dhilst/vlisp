" This function Wraps a value in a dict. DT stands
" for data type and 'wrapped' is the wrapped value,
" it's a list of values in fact.
function s:datawrap(constructor, args) abort
  return { 'DT': a:constructor, 'wrapped': a:args }
endfunc

" Receives a list of construtors as string and return
" a sumtype dict, with data construtors as mebmers of the
" dict.
function s:datatype(...) abort
  " this is a dict, it let's me use foo.bar() syntax
  let d = {}

  " a:000 is all the function arguments
  for ctrs in a:000
    " desconstruct the list by head and tail, spliting
    " the by spaces.
    let [constructor; args] = split(ctrs, ' ')
    let args = join(args, ',')
    " { _ -> _} is the lambda expression in VimL. Here
    " I'm generating a fucntion with the right arity
    " that just calls s:datawrap. This is cosmetict. It
    " would be possible to just call s:datawrap with a
    " list.
    let function = printf('{ %s -> s:datawrap("%s", [%s]) }',
      \args,
      \constructor,
      \args)
    let d[constructor] = eval(function)
  endfor

  return d
endfunc

" A generic match, calls second argument (Arm)
" if the construtors match. Very simple.
function s:match(v, ...) abort
  for [ctr, Arm] in a:000
    if a:v.DT ==# ctr
      return call(Arm, a:v.wrapped)
    endif
  endfor
endfunc

" A maybe datatype
let maybe = s:datatype('just a', 'nothing')
let foo = maybe.just(1)
echo 'match on maybe => ' . s:match(foo,
      \['just', {a -> a."!"}],
      \['nothing', {-> 'nothing'}])

let either = s:datatype('left a', 'right b')
let foo = either.right(1)
let bar = either.left('oops')
echo 'match 1 on right => ' . s:match(foo,
    \['left', {a -> printf('oops %s!', a)}],
    \['right', {a -> a + 1}])
echo 'match 2 on left' . s:match(bar,
    \['left', {a -> printf('error %s!', a)}],
    \['right', {a -> a + 1}])

let pair = s:datatype('pair a b')
let p = pair.pair(1, 2)
echo 'sum of pair(1, 2) => ' . s:match(p, ['pair', {a, b -> a + b}])

let list = s:datatype('nil', 'cons a tail')
let myList = list.cons(1, list.cons(2, list.cons(3, list.nil())))
function s:sumlist(list) abort
  return s:match(a:list,
    \['nil', {-> 0}],
    \['cons',{a, tail -> a + s:sumlist(tail)}])
endfunction

echo 'sum of 1 2 3 => ' . s:sumlist(myList)
