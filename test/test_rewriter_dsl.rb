# frozen_string_literal: true

require_relative './helper'
require_relative './dsl_rewriter'
require 'cgi'

class RewriteDSLTest < Minitest::Test

  DSL_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'dsl/original')
  DSL_COMPILED_BASE_PATH = File.join(EXAMPLES_PATH, 'dsl/compiled')


  Dir["#{DSL_EXAMPLES_PATH}/*.rb"].each do |fn|
    basename = File.basename(fn)
    name = basename.match(/^(.+)\.rb$/)[1]
    compiled_fn = File.join(DSL_COMPILED_BASE_PATH, basename)    

    original_src = IO.read(fn).chomp
    compiled_src = IO.read(compiled_fn).chomp

    define_method(:"test_rewrite_dsl_#{name}") {
      proc = eval(original_src, binding, fn)
      node = Sirop.find(proc)
      assert_kind_of Prism::Node, node

      p node if ENV['DEBUG'] == '1'
      result = DSLRewriter.new.rewrite(node)
      puts result if ENV['DEBUG'] == '1'

      assert_equal compiled_src, result
    }
  end


  # def test_dsl_rewrite_simple

  #   @b = ->(items) {
  #     h1 'foo'
  #     h2 'bar'
  #     h3 'baz'
  #   }

  #   node = Sirop.find(@b)
  #   source = DSLRewriter.new.rewrite(node)

  #   puts '$' * 40
  #   puts
  #   puts source
  #   puts
  #   exit!
  # end
end
