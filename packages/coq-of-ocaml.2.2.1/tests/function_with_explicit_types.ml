let f (n : int) (b : bool) =
  if b then
    n + 1
  else
    n - 1

let id (x : 'a) : 'a =
  x
