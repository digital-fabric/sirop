class DSLRewriter < Sirop::Rewriter
  def initialize
    super
    @html_buffer = +''
  end

  def rewrite(node)
    @buffer.clear
    @html_buffer.clear
    visit(node)
    @buffer
  end

  def emit(str)
    if @embed_mode
      @embed_buffer << str
    else
      @buffer << str
    end
  end

  def embed(pre = '', post = '')
    @embed_mode = true
    @embed_buffer = +''
    yield
    @embed_mode = false
    @html_buffer << "#{pre}#{@embed_buffer}#{post}"
  end

  def html_embed(&)
    embed('\#{CGI.escapeHTML(', ')}', &)
  end

  def tag_attr_embed(&)
    embed('\#{', '}', &)
  end

  def emit_code(loc, str = nil)
    flush_html_buffer
    super
  end

  def emit_html(str)
    @html_buffer << str
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

  def visit_call_node(node)
    return super if node.receiver

    @html_location_start ||= node.location
    args = node.arguments&.arguments
    if args
      if args[0]&.is_a?(Prism::KeywordHashNode)
        inner_text, attrs = nil, args[0]
      elsif args[1]&.is_a?(Prism::KeywordHashNode)
        inner_text, attrs = args
      else
        inner_text, args = (args && args[0]), nil
      end
    end
    block = node.block

    if inner_text
      emit_tag_open(node, attrs)
      emit_tag_inner_text(inner_text)
      emit_tag_close(node)
    elsif block
      emit_tag_open(node, attrs)
      visit(block.body)
      emit_tag_close(node)
    else
      emit_tag_open_close(node, attrs)
    end
    @html_location_end = node.location
  end

  def emit_tag_open(node, attrs)
    emit_html("<#{node.name}")
    emit_tag_attributes(node, attrs) if attrs
    emit_html(">")
  end

  def emit_tag_close(node)
    emit_html("</#{node.name}>")
  end

  def emit_tag_open_close(node, attrs)
    emit_html("<#{node.name}")
    emit_tag_attributes(node, attrs) if attrs
    emit_html("/>")
  end

  def emit_tag_inner_text(node)
    case node
    when Prism::StringNode, Prism::SymbolNode
      @html_buffer << CGI.escapeHTML(node.unescaped)
    else
      html_embed { visit(node) }
    end
  end

  def emit_tag_attributes(node, attrs)
    attrs.elements.each do |e|
      emit_html(" ")
      emit_tag_attribute_node(e.key)
      emit_html('=\"')
      emit_tag_attribute_node(e.value)
      emit_html('\"')
    end
  end

  def emit_tag_attribute_node(node)
    case node
    when Prism::StringNode, Prism::SymbolNode
      @html_buffer << node.unescaped
    else
      tag_attr_embed { visit(node) }
    end
  end
end
