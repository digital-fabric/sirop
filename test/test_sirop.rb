# frozen_string_literal: true

require_relative './helper'

class SiropTest < Minitest::Test
  def test_to_ast_proc
    o = ->() { :foo }
    ast = Sirop.to_ast(o)
    refute_nil ast
  end

  MY_PROC = ->() { :bar }

  def test_to_ast_const_proc
    ast = Sirop.to_ast(MY_PROC)
    refute_nil ast
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
    refute_nil ast
  end
end
