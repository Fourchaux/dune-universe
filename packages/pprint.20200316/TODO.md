* Fix the warnings produced by `make doc`. Review its output.

* Update the private `Makefile` so as to publish the package documentation
  on yquem (or gitlab?).

* Publish the function `blanks`.

* Try to speed up the random generator.
  `choose`, applied to a list, is too slow: use an array?
  avoid building n suspensions when only one will be forced?

* Extend `PPrintBench` to also try non-random documents of large size.
