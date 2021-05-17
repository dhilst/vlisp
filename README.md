# vlisp (will be renamed to vimlisp soon) [![Build Status](https://travis-ci.com/dhilst/vlisp.svg?branch=master)](https://travis-ci.com/dhilst/vlisp)

[What if vim users can vlisp like emacs users can elisp?](https://twitter.com/geckones/status/1384979686334283793?s=20)

I always loved elisp and working with elisp and VimL is so cumbersome. I would like to
have vlisp like emacs user have elisp so I can use FP on my configuration.

Some points:

* Since this is lisp evaluated in VimL it should be as light weight as
  possible. Premature optimization is permited here
* It should translate to VimL as reasonable as possible. Of course I would like
  to priorise Lisp semantics over VimL but it should be feasable to reason what
  vlisp would translate too.
* I would like to suport lazy evaluation on the core language and but provide
  eager evaluation for user defined functions and implement macros over
  lazy core language.
* I'm a very lazy guy, I have some spare time but I like to watch TV and
  play video games while not in computer, so the this should follow the
  principle of minimal effort, but I will call it "Poison dagger pricinple"
  here: _It must be tiny and effective, like a poison dagger._
* It must have tests. In fact I don't really care if tests are made before or
  after the code being tested, but all code must be automatically tested. Having
  private code `s:...` for example make it dificult to test, so I'm willing to
  take another path and have a kind of internal namespace but this is for the
  future.
* It's licensed over Apache-2.0
