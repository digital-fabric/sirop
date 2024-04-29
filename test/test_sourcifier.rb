# frozen_string_literal: true

require_relative './helper'

# class SorcifierTest < Minitest::Test
#   SYNTAX_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'syntax')

#   Dir["#{SYNTAX_EXAMPLES_PATH}/*.rb"].each do |fn|
#     name = File.basename(fn).match(/^(.+)\.rb$/)[1]
#     src = IO.read(fn)
#     define_method(:"test_sourcify_#{name}") {
#       proc = eval(src, binding, fn)
#       node = Sirop.to_ast(proc)
#       assert_kind_of Prism::Node, node

#       p node if ENV['DEBUG'] == '1'
#       code = Sirop.to_source(node)
#       puts code if ENV['DEBUG'] == '1'

#       assert_equal src.chomp, code
#     }
#   end

#   def test_proc_parameter_injection
#     p1 = -> { 1 }
#     node = Sirop.to_ast(p1)
#     assert_kind_of Prism::LambdaNode, node
#     assert_equal '-> { 1 }', Sirop.to_source(node).strip
#     node.inject_parameters('foo')
#     assert_equal '->(foo) { 1 }', Sirop.to_source(node).strip

#     p2 = ->() { 2 }
#     node = Sirop.to_ast(p2)
#     assert_kind_of Prism::LambdaNode, node
#     assert_equal '->() { 2 }', Sirop.to_source(node).strip
#     node.inject_parameters('foo')
#     assert_equal '->(foo) { 2 }', Sirop.to_source(node).strip

#     p3 = -> (a) { 3 }
#     node = Sirop.to_ast(p3)
#     assert_kind_of Prism::LambdaNode, node
#     assert_equal '-> (a) { 3 }', Sirop.to_source(node).strip
#     node.inject_parameters('foo')
#     assert_equal '-> (foo, a) { 3 }', Sirop.to_source(node).strip

#     p4 = -> (a:, b: 2) { 4 }
#     node = Sirop.to_ast(p4)
#     assert_kind_of Prism::LambdaNode, node
#     # binding.irb
#     assert_equal '-> (a:, b: 2) { 4 }', Sirop.to_source(node).strip
#     node.inject_parameters('foo')
#     assert_equal '-> (foo, a:, b: 2) { 4 }', Sirop.to_source(node).strip
#   end
# end

class SorcifierPrismTest < Minitest::Test
  PRISM_EXAMPLES_PATH = File.join(EXAMPLES_PATH, 'prism')
  p path: PRISM_EXAMPLES_PATH

  Dir["#{PRISM_EXAMPLES_PATH}/*.txt"].each do |fn|
    name = File.basename(fn).match(/^(.+)\.txt$/)[1]
    src = IO.read(fn)
    define_method(:"test_sourcify_prism_#{name}") {
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
