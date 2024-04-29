# frozen_string_literal: true

require 'prism'

module Sirop
  # 
  class Sourcifier < Prism::BasicVisitor
    VISIT_PLANS = {
      alias_global_variable:      [:keyword_loc, :new_name, :old_name],
      alias_method:               [:keyword_loc, :new_name, :old_name],
      and:                        [:left, :operator_loc, :right],
      assoc:                      [:key, :operator_loc, :value],
      assoc_splat:                [:operator_loc, :value],
      back_reference_read:        :emit_verbatim,
      block:                      [:opening_loc, :parameters, :body, :closing_loc],
      block_argument:             [:operator_loc, :expression],
      block_local_variable:       :emit_verbatim,
      block_parameter:            [:operator_loc, :name_loc],
      break:                      [:keyword_loc, :arguments],
      capture_pattern:            [:value, :operator_loc, :target],
      class_variable_read:        :emit_verbatim,
      class_variable_target:      :emit_verbatim,
      class_variable_write:       [:name_loc, :operator_loc, :value],
      constant_path:              [:parent, :delimiter_loc, :child],
      constant_path_write:        [:target, :operator_loc, :value],
      constant_read:              :emit_verbatim,
      constant_write:             [:name_loc, :operator_loc, :value],
      defined:                    [:keyword_loc, :lparen_loc, :value, :rparen_loc],
      embedded_statements:        [:opening_loc, :statements, :closing_loc],
      embedded_variable:          [:operator_loc, :variable],
      false:                      :emit_verbatim,
      flip_flop:                  [:left, :operator_loc, :right],
      float:                      :emit_verbatim,
      forwarding_arguments:       :emit_verbatim,
      forwarding_parameter:       :emit_verbatim,
      forwarding_super:           :emit_verbatim,
      global_variable_read:       :emit_verbatim,
      global_variable_target:     :emit_verbatim,
      global_variable_write:      [:name_loc, :operator_loc, :value],
      imaginary:                  :emit_verbatim,
      implicit_rest:              :emit_nothing,
      in:                         [:in_loc, :pattern, :then_loc],
      index_target:               [:receiver, :opening_loc, :arguments, :closing_loc],
      instance_variable_read:     :emit_verbatim,
      instance_variable_target:   :emit_verbatim,
      instance_variable_write:    [:name_loc, :operator_loc, :value],
      integer:                    :emit_verbatim,
      keyword_rest_parameter:     [:operator_loc, :name_loc],
      keyword_parameter:          :emit_verbatim,
      local_variable_and_write:   [:name_loc, :operator_loc, :value],
      local_variable_operator_write: [:name_loc, :operator_loc, :value],
      local_variable_or_write:    [:name_loc, :operator_loc, :value],
      local_variable_read:        :emit_verbatim,
      local_variable_target:      :emit_verbatim,
      local_variable_write:       [:name_loc, :operator_loc, :value],
      match_predicate:            [:value, :operator_loc, :pattern],
      match_required:             [:value, :operator_loc, :pattern],
      match_write:                [:call],
      next:                       [:keyword_loc, :arguments],
      nil:                        :emit_verbatim,
      no_keywords_parameter:      :emit_verbatim,
      numbered_parameters:        :emit_nothing,
      optional_parameter:         [:name_loc, :operator_loc, :value],
      optional_keyword_parameter: [:name_loc, :value],
      or:                         [:left, :operator_loc, :right],
      parentheses:                [:opening_loc, :body, :closing_loc],
      pinned_expression:          [:operator_loc, :lparen_loc, :expression, :rparen_loc],
      pinned_variable:            [:operator_loc, :variable],
      range:                      [:left, :operator_loc, :right],
      rational:                   :emit_verbatim,
      redo:                       :emit_verbatim,
      regular_expression:         :emit_verbatim,
      required_parameter:         :emit_verbatim,
      required_keyword_parameter: :emit_verbatim,
      rescue_modifier:            [:expression, :keyword_loc, :rescue_expression],
      rest_parameter:             [:operator_loc, :name_loc],
      retry:                      :emit_verbatim,
      return:                     [:keyword_loc, :arguments],
      self:                       :emit_verbatim,
      source_encoding:            :emit_verbatim,
      source_file:                :emit_verbatim,
      source_line:                :emit_verbatim,
      splat:                      [:operator_loc, :expression],
      string:                     [:opening_loc, :content_loc, :closing_loc],
      symbol:                     :emit_verbatim,
      true:                       :emit_verbatim,
      x_string:                   :emit_verbatim,
      yield:                      [:keyword_loc, :lparen_loc, :arguments, :rparen_loc]
    }

    attr_reader :buffer

    def initialize
      @buffer = +''
    end
  
    def to_source(node)
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
      return if loc.is_a?(Sirop::Injection)

      if @last_loc_start
        line_diff = loc.start_line - @last_loc_end.first
        if line_diff > 0
          @buffer << "\n" * line_diff
          @buffer << ' ' * loc.start_column
        elsif line_diff == 0
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

    def emit_code(loc, semicolon: false, chomp: false)
      return if !loc

      if @last_loc
        loc_loc = loc.is_a?(Prism::Node) ? loc.location : loc
        return if loc_loc.slice == @last_loc.slice && loc_loc.start_line == @last_loc.start_line && 
          loc_loc.start_column == @last_loc.start_column
      end

      semicolon ||= @semicolon
      @semicolon = false
      emit_semicolon(loc) if semicolon
      return visit(loc) if loc.is_a?(Prism::Node)

      adjust_whitespace(loc)
      str = loc.slice
      str = str.chomp if chomp
      emit(str)
    end
  
    def emit_verbatim(node)
      emit_code(node.location)
    end

    def emit_nothing(node)
      # emit nothing
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
      if @last_loc && loc.start_line == @last_loc.end_line
        if @buffer[-1] != ';' && loc.start_column > @last_loc_end[1]
          emit_str(';')
        end
      end
    end

    def method_missing(sym, node, *args)
      puts '!' * 40
      p node
      raise NotImplementedError, "Don't know how to handle #{sym}"
      visit_child_nodes(node)
    end

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
        list.each do |child|
          emit_comma if comma
          emit_code(child)
          comma = true
        end
      end
      comma
    end

    def visit_space_separated_nodes(list)
      if list
        list.each do |child|
          emit_code(child)
        end
      end
    end

    def visit_parameters_node(node)
      comma = false
      # injected_prefix is a custom attribute added by Sirop to the
      # ParametersNode class (in lib/sirop/prism_ext.rb). It is used
      # as a way to add a first parameter to a block or method.
      if node.injected_prefix
        emit_code(node.injected_prefix)
        # adjust last_loc_end for proper whitespace after comma
        @last_loc_end[1] -= 2 if @last_loc_end
        # binding.irb
        comma = true
      end
      comma = visit_comma_separated_nodes(node.requireds, comma)
      comma = visit_comma_separated_nodes(node.optionals, comma)
      if node.rest
        emit_comma if comma
        emit_code(node.rest)
        comma = true
      end
      comma = visit_comma_separated_nodes(node.posts, comma)
      comma = visit_comma_separated_nodes(node.keywords, comma)
      # if node.rest
      #   emit_comma if comma
      #   comma = true
      #   emit_code(node.rest)
      # end
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

    def visit_arguments_node(node, subscript = 0..-1)
      visit_comma_separated_nodes(node.arguments[subscript])
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
      emit_code(node.statements, semicolon: true)
      emit_code(node.consequent) if node.consequent
      emit_code(node.end_keyword_loc, semicolon: true) if node.if_keyword_loc.slice == 'if'
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

    def visit_unless_node(node)
      if !node.end_keyword_loc
        return visit_unless_node_guard(node)
      end

      emit_code(node.keyword_loc)
      emit_code(node.predicate)
      emit_code(node.then_keyword_loc)
      @semicolon = true
      emit_code(node.statements)
      emit_code(node.consequent) if node.consequent
      emit_code(node.end_keyword_loc, semicolon: true) if node.keyword_loc.slice == 'unless'
    end

    def visit_unless_node_guard(node)
      emit_code(node.statements)        
      emit_code(node.keyword_loc)
      emit_code(node.predicate)
    end

    def visit_case_node(node)
      emit_code(node.case_keyword_loc)
      emit_code(node.predicate)
      node.conditions.each { |c| emit_code(c, semicolon: true) }
      emit_code(node.consequent, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_when_node(node)
      emit_code(node.keyword_loc)
      visit_comma_separated_nodes(node.conditions)
      emit_code(node.statements, semicolon: true)
    end

    def visit_interpolated_symbol_node(node)
      emit_code(node.opening_loc)
      node.parts.each { |p| emit_code(p) }
      emit_code(node.closing_loc)
    end
    alias_method :visit_interpolated_string_node, :visit_interpolated_symbol_node

    def visit_def_node(node)
      emit_code(node.def_keyword_loc, semicolon: true)
      emit_code(node.receiver)
      emit_code(node.operator_loc)
      emit_code(node.name_loc)

      emit_code(node.lparen_loc)
      if node.parameters
        emit_code(node.parameters)
      end
      emit_code(node.rparen_loc)
      emit_code(node.equal_loc)
      emit_code(node.body, semicolon: !node.equal_loc)
      emit_code(node.end_keyword_loc, semicolon: true)
      @semicolon = true
    end

    def visit_call_node(node)
      if node.receiver && !node.call_operator_loc && !node.arguments && node.name != :[]
        return visit_call_node_unary_op(node)
      end

      if node.receiver && !node.call_operator_loc && node.name == :!
        return visit_call_node_unary_op(node)
      end

      if node.attribute_write?
        return visit_call_node_attribute_write(node)
      end

      block = node.block

      emit_code(node.receiver)
      emit_code(node.call_operator_loc)
      if (ml = node.message_loc)
        ol = node.opening_loc
        emit_message_loc = !ol || (ol.start_line != ml.start_line) || (ol.start_column != ml.start_column)
        emit_code(node.message_loc) if emit_message_loc
      end
      emit_code(node.opening_loc)
      emit_code(node.arguments)
      
      if block.is_a?(Prism::BlockArgumentNode)
        emit_comma if node.arguments && node.arguments.arguments.size > 0
        emit_code(block)
        block = nil
      end
      emit_code(node.closing_loc)
      emit_code(block)
    end

    def visit_call_node_unary_op(node)
      emit_code(node.message_loc)
      emit_code(node.opening_loc)
      emit_code(node.receiver)
      emit_code(node.closing_loc)
    end

    def visit_call_node_attribute_write(node)
      emit_code(node.receiver)
      if node.call_operator_loc
        emit_code(node.call_operator_loc)
        emit_code(node.message_loc)
      end
      emit_code(node.opening_loc)
      comma = visit_arguments_node(node.arguments, 0..-2)
      if node.block
        emit_comma if comma
        emit_code(node.block)
      end
      emit_code(node.closing_loc)
      emit_str(" = ")
      emit_code(node.arguments.arguments[-1])
      return
    end

    def visit_call_target_node(node)
      emit_code(node.receiver)
      emit_code(node.call_operator_loc)
      emit_code(node.message_loc)
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

    def visit_until_node(node)
      return visit_until_node_guard(node) if !node.closing_loc

      emit_code(node.keyword_loc)
      emit_code(node.predicate)
      emit_code(node.statements, semicolon: true)
      emit_code(node.closing_loc, semicolon: true)
    end

    def visit_until_node_guard(node)
      emit_code(node.statements)
      emit_code(node.keyword_loc)
      emit_code(node.predicate)
    end

    def visit_hash_node(node)
      emit_code(node.opening_loc)
      visit_comma_separated_nodes(node.elements)
      emit_code(node.closing_loc)
    end
  
    def visit_array_node(node)
      emit_code(node.opening_loc)
      if node.opening_loc && node.opening_loc.slice =~ /^%/
        visit_space_separated_nodes(node.elements)
      else
        visit_comma_separated_nodes(node.elements)
      end
      emit_code(node.closing_loc)
    end

    def visit_multi_write_node(node)
      emit_code(node.lparen_loc)
      comma = visit_comma_separated_nodes(node.lefts)
      if node.rest
        emit_comma if comma
        emit_code(node.rest)
        comma = true
      end
      visit_comma_separated_nodes(node.rights, comma)
      emit_code(node.rparen_loc)
      emit_code(node.operator_loc)
      emit_code(node.value)
    end

    def visit_rescue_node(node)
      emit_code(node.keyword_loc, semicolon: true)
      visit_comma_separated_nodes(node.exceptions)
      emit_code(node.operator_loc)
      emit_code(node.reference)
      emit_code(node.statements, semicolon: true)
      emit_code(node.consequent)
    end

    def visit_begin_node(node)
      emit_code(node.begin_keyword_loc) #, semicolon: true)
      emit_code(node.statements, semicolon: true)
      emit_code(node.rescue_clause)
      emit_code(node.else_clause)
      emit_code(node.ensure_clause)
      emit_code(node.end_keyword_loc, semicolon: true) if node.begin_keyword_loc
    end

    def visit_index_operator_write_node(node)
      emit_code(node.receiver)
      emit_code(node.opening_loc)
      emit_code(node.arguments)
      if node.block
        if !node.arguments.arguments.empty?
          emit_comma
        end
        emit_code(node.block)
      end
      emit_code(node.closing_loc)
      emit_code(node.operator_loc)
      emit_code(node.value)
    end
    alias_method :visit_index_and_write_node, :visit_index_operator_write_node
    alias_method :visit_index_or_write_node, :visit_index_operator_write_node

    def visit_ensure_node(node)
      emit_code(node.ensure_keyword_loc, semicolon: true)
      emit_code(node.statements, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_else_node(node)
      emit_code(node.else_keyword_loc, semicolon: node.else_keyword_loc.slice == 'else')
      emit_code(node.statements, semicolon: node.else_keyword_loc.slice == 'else')
    end

    def visit_case_match_node(node)
      emit_code(node.case_keyword_loc)
      emit_code(node.predicate)
      @semicolon = true
      visit_comma_separated_nodes(node.conditions)
      emit_code(node.end_keyword_loc)
    end

    def visit_class_node(node)
      emit_code(node.class_keyword_loc)
      emit_code(node.constant_path)
      emit_code(node.inheritance_operator_loc)
      emit_code(node.superclass)
      emit_code(node.body, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_module_node(node)
      emit_code(node.module_keyword_loc)
      emit_code(node.constant_path)
      emit_code(node.body, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_singleton_class_node(node)
      emit_code(node.class_keyword_loc)
      emit_code(node.operator_loc)
      emit_code(node.expression)
      emit_code(node.body, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_interpolated_x_string_node(node)
      emit_code(node.opening_loc)
      node.parts.each { |p| emit_code(p) }
      emit_code(node.closing_loc, chomp: true)
    end

    def visit_for_node(node)
      emit_code(node.for_keyword_loc)
      emit_code(node.index)
      emit_code(node.in_keyword_loc)
      emit_code(node.collection)
      emit_code(node.do_keyword_loc)
      emit_code(node.statements, semicolon: true)
      emit_code(node.end_keyword_loc, semicolon: true)
    end

    def visit_multi_target_node(node)
      emit_code(node.lparen_loc)
      comma = visit_comma_separated_nodes(node.lefts)
      if node.rest
        emit_comma if comma
        emit_code(node.rest)
        comma = true
      end
      visit_comma_separated_nodes(node.rights, comma)
      emit_code(node.rparen_loc)
    end

    def visit_find_pattern_node(node)
      emit_code(node.constant)
      emit_code(node.opening_loc)
      emit_code(node.left)
      comma = node.left
      comma = visit_comma_separated_nodes(node.requireds, comma)
      if node.right
        emit_comma if comma
        emit_code(node.right)
      end
      emit_code(node.closing_loc)
    end

    def visit_array_pattern_node(node)
      emit_code(node.constant)
      emit_code(node.opening_loc)
      comma = visit_comma_separated_nodes(node.requireds, comma)
      if node.rest
        emit_comma if comma
        emit_code(node.rest)
        comma = true
      end
      visit_comma_separated_nodes(node.posts, comma)
      emit_code(node.closing_loc)
    end

    def visit_hash_pattern_node(node)
      emit_code(node.constant)
      emit_code(node.opening_loc)
      visit_comma_separated_nodes(node.elements)
      emit_code(node.closing_loc)
    end

    def visit_statements_node(node)
      first = true
      node.body&.each do |n|
        @semicolon = !first
        visit(n)
        first = false
      end
    end

    def visit_block_parameters_node(node)
      emit_code(node.opening_loc)
      emit_code(node.injected_parameters)
      emit_code(node.parameters)
      @semicolon = true if node.parameters
      visit_comma_separated_nodes(node.locals)
      emit_code(node.closing_loc)
      @semicolon = false
    end

    def visit_lambda_node(node)
      emit_code(node.operator_loc)
      emit_code(node.parameters)
      emit_code(node.opening_loc)
      emit_code(node.body, semicolon: node.opening_loc.slice == 'do')
      emit_code(node.closing_loc, semicolon: node.closing_loc.slice == 'end')
    end

    def visit_interpolated_regular_expression_node(node)
      emit_code(node.opening_loc)
      node.parts.each { |p| emit_code(p) }
      emit_code(node.closing_loc)
    end

    def visit_super_node(node)
      emit_code(node.keyword_loc)
      emit_code(node.lparen_loc)
      emit_code(node.arguments)
      emit_block_pre_rparen = node.block.is_a?(Prism::BlockArgumentNode)
      if emit_block_pre_rparen
        emit_comma if node.arguments
        emit_code(node.block)
      end
      emit_code(node.rparen_loc)
      emit_code(node.block) if !emit_block_pre_rparen
    end

    def visit_undef_node(node)
      emit_code(node.keyword_loc)
      visit_comma_separated_nodes(node.names)
    end

  end
end
