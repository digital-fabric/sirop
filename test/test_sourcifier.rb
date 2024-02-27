# frozen_string_literal: true

require_relative './helper'

class SorcifierTest < Minitest::Test
  SYNTAX_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'syntax')

  Dir["#{SYNTAX_EXAMPLES_PATH}/*.rb"].each do |fn|
    name = File.basename(fn).match(/^(.+)\.rb$/)[1]
    src = IO.read(fn)
    define_method(:"test_sourcify_#{name}") {
      proc = eval(src, binding, fn)
      node = Sirop.to_ast(proc)
      assert_kind_of Prism::Node, node

      p node if ENV['DEBUG'] == '1'
      code = Sirop.to_source(node)
      puts code if ENV['DEBUG'] == '1'

      assert_equal src.chomp, code
    }
  end
end
