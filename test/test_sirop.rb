# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'sirop'

EXAMPLES_PATH = File.join(__dir__, 'examples')

module Kernel
  def load_code(name)
    fn = File.join(EXAMPLES_PATH, "#{name}.rb")
    eval(IO.read(fn), binding, fn)
  end
end

class FindTest < Minitest::Test
  def test_find_lambda_1
    proc = load_code('find')[:lambda_1]
    node = Sirop.find(proc)

    assert_kind_of Prism::LambdaNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal '->(x) { x + 1 }', node.slice
  end

  def test_find_lambda_2
    proc = load_code('find')[:lambda_2]
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal 'lambda { |x, y| x + y }', node.slice
  end

  def test_find_proc_1
    proc = load_code('find')[:proc_1]
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc {\n    :foo\n  }", node.slice
  end

  def test_find_proc_2
    proc = load_code('find')[:proc_2]
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc do\n    :bar\n  end", node.slice
  end
end

class RewriteVerbatimTest < Minitest::Test
  SYNTAX_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'syntax')

  Dir["#{SYNTAX_EXAMPLES_PATH}/*.rb"].each do |fn|
    name = File.basename(fn).match(/^(.+)\.rb$/)[1]
    src = IO.read(fn)
    define_method(:"test_rewrite_verbatim_#{name}") {
      proc = eval(src, binding, fn)
      node = Sirop.find(proc)

      assert_equal src.chomp, Sirop.to_source(node)
    }
  end
end
