# frozen_string_literal: true

require 'prism'
require 'sirop'

class Mutator
  def initialize(mutate_block)
    @mutate_block = mutate_block
  end
  
  def method_missing(sym, n)= sym !~ /^visit_/ ? super(sym, n) : visit(n)

  def visit(n)
    n2 = @mutate_block.(n)
    return n2 if n2 != n

    mutations = {}
    n.deconstruct_keys(nil).each do |k, v|
      if v.is_a?(Prism::Node)
        res = visit(v)
        mutations[k] = res if (res != v)
      elsif v.is_a?(Array) && v[0].is_a?(Prism::Node)
        v2 = v.map { visit(it) }
        mutations[k] = v2 if v2 != v
      end
    end
    p(mutations:) if !mutations.empty?
    mutations.empty? ? n : n.copy(**mutations)
  end
end

def mutate(ast, **mutations, &block)
  block ||= ->(n) do
    if n.is_a?(Prism::StatementsNode) && mutations.has_key?(n.body)
      mutations[n.body]
    else
      mutations.has_key?(n) ? mutations[n] : n
    end
  end
  ast.accept(Mutator.new(block))
end

def quote(&block)
  Sirop.to_ast(block).body
end

# ast = Prism.parse('v = (1; 2)').value.statements.body[0]
# p ast
# exit

# o = mutate(Prism.parse('def x; 42; end').value.statements) { |n|
#   n.is_a?(Prism::IntegerNode) ? quote { (43) } : n
# }
# puts '*' * 40
# puts Sirop.to_source(o).gsub(/\n{2,}/m, "\n")

puts

ast = Prism.parse('def y(z); 44; end').value.statements
replacement = quote { 45 }
puts '*' * 40
puts Sirop.to_source(ast).gsub(/\n{2,}/m, "\n")
o = mutate(ast, ast.body[0].body => replacement)
puts Sirop.to_source(o).gsub(/\n{2,}/m, "\n")
