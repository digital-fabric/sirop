# frozen_string_literal: true

require 'prism'

module Sirop
  class Rewriter < Prism::BasicVisitor
    attr_reader :buffer

    def initialize
      @buffer = +''
    end
  
    def rewrite(node)
      @buffer.clear
      visit(node)
      @buffer
    end
  
    def loc_start(loc)
      [loc.start_line, loc.start_column]
    end
  
    def loc_end(loc)
      [loc.end_line, loc.end_column]
    end

    def before_emit
    end

    def emit(str)
      @buffer << str
    end

    def adjust_whitespace(loc)
      if @last_loc_start
        if @last_loc_start.first != loc.start_line
          @buffer << "\n"
          buffer << ' ' * loc.start_column
        else
          ofs = loc.start_column - @last_loc_end.last
          if ofs > 0
            buffer << ' ' * ofs
          end
        end
      else
        # empty buffer
        buffer << ' ' * loc.start_column
      end
      @last_loc_start = loc_start(loc)
      @last_loc_end = loc_end(loc)
    end

    def emit_code(loc, str = nil)
      return if !loc

      str ||= loc.slice
      before_emit
      adjust_whitespace(loc)
      emit(str)
    end
  
    def emit_verbatim(node)
      emit_code(node.location)
    end
  
    def emit_comma
      before_emit

      # somewhat hacky - we insert a comma in there, and increment the last
      # column
      emit ','
      @last_loc_end[1] += 1
    end
  
    def method_missing(sym, node, *args)
      p method_missing: sym
      visit_child_nodes(node)
    end

    VISIT_CHILDREN_NODE_TYPES = %w{
      assoc
      statements
    }

    EMIT_VERBATIM_NODE_TYPES = %w{
      integer
      local_variable_read
      required_parameter
      string
      symbol
    }

    VISIT_CHILDREN_NODE_TYPES.each do |sym|
      alias_method :"visit_#{sym}_node", :visit_child_nodes
    end
    EMIT_VERBATIM_NODE_TYPES.each do |sym|
      alias_method :"visit_#{sym}_node", :emit_verbatim
    end
  
    def visit_lambda_node(node)
      emit_code(node.operator_loc)
      visit(node.parameters) if node.parameters
      emit_code(node.opening_loc)
      visit(node.body) if node.body
      emit_code(node.closing_loc)
    end
  
    def visit_call_node(node)
      emit_code(node.receiver.location) if node.receiver
      emit_code(node.message_loc)
      emit_code(node.opening_loc)
      visit(node.arguments)
      emit_code(node.closing_loc)
      visit(node.block) if node.block
    end

    def visit_block_node(node)
      emit_code(node.opening_loc)
      visit(node.parameters) if node.parameters
      visit(node.body)
      emit_code(node.closing_loc)
    end

    def visit_block_parameters_node(node)
      emit_code(node.opening_loc)
      visit(node.parameters)
      emit_code(node.closing_loc)
    end

    def visit_parameters_node(node)
      comma = false
      node.requireds&.each_with_index do |n|
        emit_comma if comma
        visit(n)
        comma = true
      end
      node.optionals&.each_with_index do |n|
        emit_comma if comma
        visit(n)
        comma = true
      end
    end
  
    def visit_arguments_node(node)
      node.arguments.each_with_index do |child, idx|
        emit_comma if idx > 0
        visit(child)
      end
    end
  
    def visit_keyword_hash_node(node)
      node.elements.each_with_index do |child, idx|
        emit_comma if idx > 0
        visit(child)
      end
    end

    def visit_if_node(node)
      if !node.if_keyword_loc
        return visit_if_node_ternary(node)
      elsif !node.end_keyword_loc
        return visit_if_node_guard(node)
      end

      emit_code(node.if_keyword_loc)
      visit(node.predicate)
      emit_code(node.then_keyword_loc)
      visit(node.statements)
      visit(node.consequent) if node.consequent
      emit_code(node.end_keyword_loc) if node.if_keyword_loc.slice == 'if'
    end

    def visit_if_node_ternary(node)
      visit(node.predicate)
      emit_code(node.then_keyword_loc)
      visit(node.statements)
      visit(node.consequent)
    end

    def visit_if_node_guard(node)
      visit(node.statements)        
      emit_code(node.if_keyword_loc)
      visit(node.predicate)
    end

    def visit_else_node(node)
      emit_code(node.else_keyword_loc)
      visit(node.statements)
    end

    def visit_parentheses_node(node)
      emit_code(node.opening_loc)
      visit(node.body)
      emit_code(node.closing_loc)
    end
  end  
end
