# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'sirop'

module Kernel
  CODE_BASE_PATH = File.join(__dir__, 'examples')

  def load_code(name)
    fn = File.join(CODE_BASE_PATH, "#{name}.rb")
    eval(IO.read(fn), binding, fn)
  end
end

class FindTest < Minitest::Test
  def test_find_lambda_1
    proc = load_code(:lambda_1)
    node = Sirop.find(proc)

    assert_kind_of Prism::LambdaNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal '->(x) { x + 1 }', node.slice
  end

  def test_find_lambda_2
    proc = load_code(:lambda_2)
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal 'lambda { |x, y| x + y }', node.slice
  end

  def test_find_proc_1
    proc = load_code(:proc_1)
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc {\n  :foo\n}", node.slice
  end

  def test_find_proc_2
    proc = load_code(:proc_2)
    node = Sirop.find(proc)

    assert_kind_of Prism::CallNode, node
    assert_equal proc.source_location[1], node.location.start_line
    assert_equal "proc do\n  :bar\nend", node.slice
  end
end
