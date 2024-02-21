# frozen_string_literal: true

require 'prism'

module Sirop
  class ProcFinder < Prism::BasicVisitor
    def initialize(proc, lineno)
      @proc = proc
      @lineno = lineno
    end

    def find(program)
      catch(@proc) do
        visit(program)
        nil
      end
    end

    def found!(node)
      throw @proc, node
    end
  
    def visit_lambda_node(node)
      if node.location.start_line == @lineno
        found!(node)
      else
        visit_child_nodes(node)
      end
    end

    def visit_call_node(node)
      case node.name
      when :proc, :lambda
        if node.block && node.block.location.start_line == @lineno
          found!(node)
        end
      end
    end

    def method_missing(sym, node, *args)
      visit_child_nodes(node)
    end
  end  
end
