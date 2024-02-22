# frozen_string_literal: true

require 'prism'

module Sirop
  class MethodFinder < Prism::BasicVisitor
    def initialize(method, lineno)
      @method = method
      @lineno = lineno
    end

    def find(program)
      catch(@method) do
        visit(program)
        nil
      end
    end

    def found!(node)
      throw @method, node
    end

    def visit_def_node(node)
      if node.name == @method.name && node.location.start_line == @lineno
        found!(node)
      else
        visit_child_nodes(node)
      end
    end

    def method_missing(sym, node, *args)
      visit_child_nodes(node)
    end
  end  
end
