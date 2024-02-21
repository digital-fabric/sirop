class DSLRewriter < Sirop::Rewriter
  def initialize
    super
    @html_buffer = +''
  end

  def rewrite(node)
    @in_body = nil
    @buffer.clear
    @html_buffer.clear
    visit(node)
    @buffer
  end

  def emit(str)
    if @in_html
      @html_code_buffer << str
    else
      @buffer << str
    end
  end

  def emit_code(loc, str = nil)
    return if !loc

    flush_html_buffer
    super
  end

  def emit_html(str)
    @html_buffer << str
  end

  def emit_html_from_node(node)
    if node.is_a?(Prism::StringNode)
      @html_buffer << CGI.escapeHTML(node.unescaped)
    else
      @in_html = true
      @html_code_buffer = +''
      visit(node)
      @in_html = false
      @html_buffer << "\#{CGI.escapeHTML(#{@html_code_buffer})}"
    end
  end

  def flush_html_buffer
    return if @html_buffer.empty?

    if !@html_buffer.empty?
      adjust_whitespace(@html_location_start) if @html_location_start
      @buffer << "__buffer__ << \"#{@html_buffer}\""
      @html_buffer.clear
      @last_loc_end = loc_end(@html_location_end) if @html_location_end
    end
    @html_location_start = nil
    @html_location_end = nil
  end

  def visit_statements_node(node)
    return super if @in_body

    @in_body = true
    super
    flush_html_buffer
  end

  def visit_call_node(node)
    return super if node.receiver

    @html_location_start ||= node.location
    if node.block
      visit_call_node_with_block(node)
    elsif node.arguments
      emit_html("<#{node.name}>")
      emit_html_from_node(node.arguments.arguments[0])
      emit_html("</#{node.name}>")
    else
      emit_html("<#{node.name}/>")
    end
    @html_location_end = node.location
  end

  def visit_call_node_with_block(node)
    if node.arguments
      # do nothing
    else
      emit_html("<#{node.name}>")
      visit(node.block.body)
      emit_html("</#{node.name}>")
    end
  end
end
