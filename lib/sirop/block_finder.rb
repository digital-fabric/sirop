# frozen_string_literal: true

module Sirop
  class BlockFinder < Prism::BasicVisitor
    attr_accessor :block_node
  
    def initialize(proc, lineno)
      @proc = proc
      @lineno = lineno
    end

    def find(program)
      # p program
      # puts
      catch(@proc) {
        visit(program)
        nil
      }  
    end
  
    def visit_lambda_node(node)
      if node.location.start_line == @lineno
        throw @proc, node
      else
        visit_child_nodes(node)
      end
    end

    def visit_call_node(node)
      case node.name
      when :proc, :lambda
        if node.block && node.block.location.start_line == @lineno
          throw @proc, node
        end
      end
    end

    def method_missing(sym, node, *args)
      visit_child_nodes(node)
    end
  end  
end
