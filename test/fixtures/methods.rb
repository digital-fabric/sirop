
class Foo
  def foo; :foo; end
  
  def bar(x)
    p x
    yield
  end

  def baz(&)
    bar(42, &)
  end
end
