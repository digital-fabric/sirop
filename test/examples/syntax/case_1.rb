->(x) {
  case x
  when :foo
    'foo'
  when :bar, :baz
    x.to_s
  else
    nil
  end
}
