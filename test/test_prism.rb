# frozen_string_literal: true

require_relative './helper'
require_relative './fixtures/methods'

class PrismTest < Minitest::Test
  def test_to_ast_lambda_1
    proc = load_code('find')[:lambda_1]
    node = Sirop.to_ast(proc)

    assert_kind_of Prism::LambdaNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal '->(x) { x + 1 }', node.slice
  end

  def test_to_ast_lambda_2
    proc = load_code('find')[:lambda_2]
    node = Sirop.to_ast(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal 'lambda { |x, y| x + y }', node.slice
  end

  def test_to_ast_proc_1
    proc = load_code('find')[:proc_1]
    node = Sirop.to_ast(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc {\n    :foo\n  }", node.slice
  end

  def test_to_ast_proc_2
    proc = load_code('find')[:proc_2]
    node = Sirop.to_ast(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc do\n    :bar\n  end", node.slice
  end

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
  
  def test_to_ast_method
    f = Foo.new

    m = f.method(:foo)
    node = Sirop.to_ast(m)
    assert_kind_of Prism::DefNode, node
    assert_equal "def foo; :foo; end", node.slice

    m = f.method(:bar)
    node = Sirop.to_ast(m)
    assert_kind_of Prism::DefNode, node
    assert_equal "def bar(x)\n      p x\n      yield\n    end", node.slice
  end

  def test_to_ast_unbound_method
    m = Foo.instance_method(:foo)
    node = Sirop.to_ast(m)
    assert_kind_of Prism::DefNode, node
    assert_equal "def foo; :foo; end", node.slice

    m = Foo.instance_method(:bar)
    node = Sirop.to_ast(m)
    assert_kind_of Prism::DefNode, node
    assert_equal "def bar(x)\n      p x\n      yield\n    end", node.slice
  end

  def test_to_string
    str = Sirop.to_source(Foo.instance_method(:foo))
    assert_equal "def foo; :foo; end", str.strip

    str = Sirop.to_source(Foo.instance_method(:bar))
    assert_equal "def bar(x)\n      p x\n      yield\n    end", str.strip

    str = Sirop.to_source(Foo.instance_method(:baz))
    assert_equal "def baz(&)\n      bar(42, &)\n    end", str.strip
  end
end
