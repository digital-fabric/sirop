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

    def emit(str)
      @buffer << str
    end

    def adjust_whitespace(loc)
      if @last_loc_start
        if @last_loc_end.first != loc.start_line
          @buffer << "\n" * (loc.start_line - @last_loc_end.first)
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
      @last_loc = loc
      @last_loc_start = loc_start(loc)
      @last_loc_end = loc_end(loc)
    end

    def emit_code(loc, semicolon: false)
      return if !loc

      emit_semicolon(loc) if semicolon
      return visit(loc) if loc.is_a?(Prism::Node)

      adjust_whitespace(loc)
      emit(loc.slice)
    end
  
    def emit_verbatim(node)
      emit_code(node.location)
    end

    def emit_str(str)
      emit(str)
      @last_loc_end[1] += str.size
    end
  
    def emit_comma
      emit_str(',')
    end

    def emit_semicolon(loc)
      loc = loc.location if loc.is_a?(Prism::Node)
      emit_str(';') if loc.start_line == @last_loc.end_line
    end

    def method_missing(sym, node, *args)
      puts '!' * 40
      p node
      raise NotImplementedError, "Don't know how to handle #{sym}"
      visit_child_nodes(node)
    end

    VISIT_PLANS = {
      and:                    [:left, :operator_loc, :right],
      assoc:                  :visit_child_nodes,
      assoc_splat:            [:operator_loc, :value],
      block:                  [:opening_loc, :parameters, :body, :closing_loc],
      block_argument:         [:operator_loc, :expression],
      block_parameter:        [:operator_loc, :name_loc],
      block_parameters:       [:opening_loc, :parameters, :closing_loc],
      break:                  [:keyword_loc, :arguments],
      constant_path:          [:parent, :delimiter_loc, :child],
      constant_read:          :emit_verbatim,
      else:                   [:else_keyword_loc, :statements],
      embedded_statements:    [:opening_loc, :statements, :closing_loc],
      false:                  :emit_verbatim,
      integer:                :emit_verbatim,
      keyword_rest_parameter: [:operator_loc, :name_loc],
      lambda:                 [:operator_loc, :parameters, :opening_loc, :body,
                               :closing_loc],
      local_variable_read:    :emit_verbatim,
      local_variable_write:   [:name_loc, :operator_loc, :value],
      next:                   [:keyword_loc, :arguments],
      nil:                    :emit_verbatim,
      optional_parameter:     [:name_loc, :operator_loc, :value],
      or:                     [:left, :operator_loc, :right],
      parentheses:            [:opening_loc, :body, :closing_loc],
      required_parameter:     :emit_verbatim,
      rest_parameter:         [:operator_loc, :name_loc],
      splat:                  [:operator_loc, :expression],
      statements:             :visit_child_nodes,
      string:                 :emit_verbatim,
      symbol:                 :emit_verbatim,
      true:                   :emit_verbatim,
      yield:                  [:keyword_loc, :lparen_loc, :arguments, :rparen_loc],
    }

    VISIT_PLANS.each do |key, plan|
      sym = :"visit_#{key}_node"
      define_method(sym) { |n| visit_plan(plan, n) }
    end
  
    def visit_plan(plan, node)
      return send(plan, node) if plan.is_a?(Symbol)

      insert_semicolon = false
      plan.each_with_index do |sym, idx|
        if sym == :semicolon
          insert_semicolon = true
          next
        end

        obj = node.send(sym)
        emit_code(obj, semicolon: insert_semicolon)
        insert_semicolon = false
      end
    end

    def visit_comma_separated_nodes(list, comma = false)
      if list
        list.each_with_index do |child, idx|
          emit_comma if comma
          emit_code(child)
          comma = true
        end
      end
      comma
    end

    def visit_parameters_node(node)
      comma = visit_comma_separated_nodes(node.requireds)
      comma = visit_comma_separated_nodes(node.optionals, comma)
      comma = visit_comma_separated_nodes(node.posts, comma)
      if node.rest
        emit_comma if comma
        comma = true
        emit_code(node.rest)
      end
      if node.keyword_rest
        emit_comma if comma
        comma = true
        emit_code(node.keyword_rest)
      end
      if node.block
        emit_comma if comma
        comma = true
        emit_code(node.block)
      end
    end

    def visit_arguments_node(node)
      visit_comma_separated_nodes(node.arguments)
    end
  
    def visit_keyword_hash_node(node)
      visit_comma_separated_nodes(node.elements)
    end

    def visit_if_node(node)
      if !node.if_keyword_loc
        return visit_if_node_ternary(node)
      elsif !node.end_keyword_loc
        return visit_if_node_guard(node)
      end

      emit_code(node.if_keyword_loc)
      emit_code(node.predicate)
      emit_code(node.then_keyword_loc)
      emit_code(node.statements)
      emit_code(node.consequent) if node.consequent
      emit_code(node.end_keyword_loc) if node.if_keyword_loc.slice == 'if'
    end

    def visit_if_node_ternary(node)
      emit_code(node.predicate)
      emit_code(node.then_keyword_loc)
      emit_code(node.statements)
      emit_code(node.consequent)
    end

    def visit_if_node_guard(node)
      emit_code(node.statements)        
      emit_code(node.if_keyword_loc)
      emit_code(node.predicate)
    end

    def visit_case_node(node)
      emit_code(node.case_keyword_loc)
      emit_code(node.predicate)
      node.conditions.each { |c| emit_code(c) }
      emit_code(node.consequent)
      emit_code(node.end_keyword_loc)
    end

    def visit_when_node(node)
      emit_code(node.keyword_loc)
      visit_comma_separated_nodes(node.conditions)
      emit_code(node.statements)
    end

    def visit_interpolated_symbol_node(node)
      emit_code(node.opening_loc)
      node.parts.each { |p| emit_code(p) }
      emit_code(node.closing_loc)
    end
    alias_method :visit_interpolated_string_node, :visit_interpolated_symbol_node

    def visit_def_node(node)
      emit_code(node.def_keyword_loc)
      emit_code(node.name_loc)
      last_loc = node.name_loc

      if node.parameters
        emit_str('(')
        emit_code(node.parameters)
        emit_str(')')
        last_loc = node.parameters.location
      end

      emit_code(node.body, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_call_node(node)
      if node.receiver && !node.call_operator_loc && !node.arguments
        return visit_call_node_unary_op(node)
      end

      block = node.block

      emit_code(node.receiver)
      emit_code(node.call_operator_loc)
      emit_code(node.message_loc)
      emit_code(node.opening_loc)
      emit_code(node.arguments)
      
      if block.is_a?(Prism::BlockArgumentNode)
        emit_comma if node.arguments&.arguments.size > 0
        emit_code(block)
        block = nil
      end
      emit_code(node.closing_loc)
      emit_code(block)
    end

    def visit_call_node_unary_op(node)
      emit_code(node.message_loc)
      emit_code(node.receiver)
    end

    def visit_while_node(node)
      return visit_while_node_guard(node) if !node.closing_loc

      emit_code(node.keyword_loc)
      emit_code(node.predicate)
      emit_code(node.statements, semicolon: true)
      emit_code(node.closing_loc, semicolon: true)
    end

    def visit_while_node_guard(node)
      emit_code(node.statements)
      emit_code(node.keyword_loc)
      emit_code(node.predicate)
    end
  end
end
