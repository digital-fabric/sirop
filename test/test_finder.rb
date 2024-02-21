# frozen_string_literal: true

require_relative './helper'

class FinderTest < Minitest::Test
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

