# frozen_string_literal: true

require_relative './helper'

class SiropTest < Minitest::Test
  def test_to_ast_proc
    o = proc { |x| :foo }
    ast = Sirop.to_ast(o)
    assert_kind_of Prism::BlockNode, ast
  end

  def test_to_ast_lambda
    o = lambda { :foo }
    ast = Sirop.to_ast(o)
    assert_kind_of Prism::BlockNode, ast
  end

  def test_to_ast_arrow
    o = ->() { :foo }
    ast = Sirop.to_ast(o)
    assert_kind_of Prism::LambdaNode, ast
  end

  MY_PROC = ->() { :bar }

  def test_to_ast_const_proc
    ast = Sirop.to_ast(MY_PROC)
    assert_kind_of Prism::LambdaNode, ast
  end

  class ProcWrapper < Proc
    attr_reader :block

    def initialize(&block)
      @block = block
      super(&block)
    end
  end

  def test_proc_wrapper
    w = ProcWrapper.new {
      :wrapped
    }

    ast = Sirop.to_ast(w)
    assert_kind_of Prism::BlockNode, ast
  end
end
