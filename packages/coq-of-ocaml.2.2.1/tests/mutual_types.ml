type foo = string

type 'a tree = Tree of 'a node list

and 'a node =
  | Leaf of string
  | Node of 'a tree

and 'b double = 'b * 'b simple

and 'b simple = 'b

and 'a unrelated = Unrelated of ('a simple) double

type ind =
  | Ind of int re

and 'a re = { payload : 'a; message : string }

and re_bis = { bis : unit }
