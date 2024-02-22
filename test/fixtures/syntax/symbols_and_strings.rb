->(x) {
  p :*
  p :foo
  p :"#{1 + 2}::#{ 'a' + 'b' }"

  'abc'
  'abc\'def'

  "abc"
  "abc\"def\t\n"

  "\x01\x02"

  "a#{:b}c#{42}"
}
