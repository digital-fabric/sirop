# Sirop

Sirop is a Ruby gem for manipulating Ruby source code. Sirop is very young, so
the following information might be incomplete, out of date, or simply wrong!

## Use Cases

Some of the use cases addressed by Sirop are:

- Compile DSLs into optimized Ruby code. This is especially interesting for HTML
  templating DSLs in libraries like Phlex, Papercraft etc.
  [Example](https://github.com/digital-fabric/sirop/blob/main/test/dsl_compiler.rb)
- Get the source of a given block or method.
- Rewrite parts of Ruby code, for implementing Ruby macros (and why not?).

## Limitations

- Sirop supports Ruby 3.2 or newer.
- Sirop can be used only on blocks and methods defined in a file, so cannot
  really be used on dynamically `eval`'d Ruby code, or in an IRB/Pry session.

## Getting the AST/source of a Ruby proc or method

To get the AST of a proc or a method, use `Sirop.to_ast`:

```ruby
# for a proc
mul = ->(x, y) { x * y }
Sirop.to_ast(mul) #=> ...

# for a method
def foo; :bar; end
Sirop.to_ast(method(:foo)) #=> ...
```

To get the source of a proc or a method, use `Sirop.to_source`:

```ruby
mul = ->(x, y) { x * y }
Sirop.to_source(mul) #=> "->(x, y) { x * y }"

def foo; :bar; end
Sirop.to_source(method(:foo)) #=> "def foo; :bar; end"
```

## Rewriting Ruby code

You can consult the [DSL compiler
example](https://github.com/digital-fabric/sirop/blob/main/test/dsl_compiler.rb). This example intercepts method calls by defining a `visit_call_node` method:

```ruby
# Annotated with some explanations
def visit_call_node(node)
  # don't rewrite if the call has a receiver
  return super if node.receiver

  # set HTML location start
  @html_location_start ||= node.location
  # get method arguments...
  inner_text, attrs = tag_args(node)
  # and block
  block = node.block

  # emit HTML tag according to given arguments
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
  # set HTML location end
  @html_location_end = node.location
end
```

## Future directions

- Implement a macro expander with support for `quote`/`unquote`:

  ```ruby
  trace_macro = Sirop.macro do |ast|
    source = Sirop.to_source(ast)
    quote do
      result = unquote(ast)
      puts "The result of #{source} is: #{result}"
      result
    end
  end

  def add(x, y)
    trace(x + y)
  end

  Sirop.expand_macros(method(:add), trace: trace_macro)
  ```

- Implement a DSL compiler with hooks for easier usage in DSL libraries.

## Contributing

We gladly welcome contributions from anyone! Some areas that need work currently
are:

- Documentation
- More test cases for Ruby syntax in the Sirop tests. Look here:
  https://github.com/digital-fabric/sirop/tree/main/test/fixtures

Please feel free to contribute PR's and issues