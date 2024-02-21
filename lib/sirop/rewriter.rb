# frozen_string_literal: true

require 'prism'

module Sirop
  class Rewriter < Prism::BasicVisitor
    attr_reader :buffer
  
    def initialize
      @buffer = +''
    end
  
    def loc_start(loc)
      [loc.start_line, loc.start_column]
    end
  
    def loc_end(loc)
      [loc.end_line, loc.end_column]
    end
  
    def emit_verbatim(node)
      emit_code(node.location)
    end
  
    def emit_code(loc, str = nil)
      return if !loc

      str ||= loc.slice
      # p emit: loc, start: loc_start(loc), end: loc_end(loc), str: loc.slice
      if @last_loc_start
        if @last_loc_start.first != loc.start_line
          @buffer << "\n"
          @buffer << ' ' * loc.start_column
        else
          ofs = loc.start_column - @last_loc_end.last
          if ofs > 0
            @buffer << ' ' * ofs
          end
        end
      else
        # empty buffer
        @buffer << ' ' * loc.start_column
      end
      @last_loc_start = loc_start(loc)
      @last_loc_end = loc_end(loc)
      @buffer << str
    end
  
    def emit_comma
      # somewhat hacky - we insert a comma in there, and increment the last
      # column
      @buffer << ','
      @last_loc_end[1] += 1
    end
  
    VISIT_CHILDREN_NODE_TYPES = %w{
      assoc
      statements
    }

    EMIT_VERBATIM_NODE_TYPES = %w{
      integer
      local_variable_read
      required_parameter
      symbol
    }

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

    VISIT_CHILDREN_NODE_TYPES.each do |sym|
      alias_method :"visit_#{sym}_node", :visit_child_nodes
    end
    EMIT_VERBATIM_NODE_TYPES.each do |sym|
      alias_method :"visit_#{sym}_node", :emit_verbatim
    end
  
    def method_missing(sym, node, *args)
      p method_missing: sym
      visit_child_nodes(node)
    end
  end  
end
