# frozen_string_literal: true

require_relative './helper'
require_relative './dsl_rewriter'
require 'cgi'

class DSLRewriterTest < Minitest::Test

  DSL_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'dsl/original')
  DSL_COMPILED_BASE_PATH = File.join(EXAMPLES_PATH, 'dsl/compiled')


  Dir["#{DSL_EXAMPLES_PATH}/*.rb"].each do |fn|
    basename = File.basename(fn)
    name = basename.match(/^(.+)\.rb$/)[1]
    compiled_fn = File.join(DSL_COMPILED_BASE_PATH, basename)    

    original_src = IO.read(fn).chomp
    compiled_src = IO.read(compiled_fn).chomp

    define_method(:"test_rewrite_dsl_#{name}") do
      proc = eval(original_src, binding, fn)
      node = Sirop.to_ast(proc)
      assert_kind_of Prism::Node, node

      p node if ENV['DEBUG'] == '1'
      result = DSLRewriter.new.rewrite(node)
      puts result if ENV['DEBUG'] == '1'

      assert_equal compiled_src, result
    end
  end
end
