## Simple

```ruby
# inline lambda generation
def make_adder(v)
  ->(x) { x + v }
end

# string interpolation
def make_adder(v)
  eval("->(x) { x + #{v.inspect} }")
end

# quote/unquote
def make_adder(v)
  ast = quote { ->(x) { x + unquote(v) } }
  eval(ast.to_source)
end
```

## Validator

An example of how such a mechanism may be used, here's how we may define a
general-purpose argument validator:

```ruby
# inline lambda generation
def create_validator(*conds)
  ->(v) {
    conds.each { raise unless it === v }
    v
  }
end

# string interpolation
def create_validator(*conds)
  eval([
    "->(v) { ",
    *(conds.map { "raise unless (#{it.inspect}) === v;" }),
    "v }"
  ].join)
end

# quote/unquote
def create_validator(*conds)
  # quote returns an AST
  ast = quote {
    ->(v) {
      unquote(
        conds.map { |c| quote { unquote(c) === v } }
      )
      v
    }
  }
  eval(ast.to_source)
end
```

## Papercraft template compiler

```ruby
# source:
t = ->(foo) {
  div {
    if foo
      h1 'foo'
    else
      h2 'bar'
    end
  }
}

# compiled:
->(__buffer__, foo) {
  __buffer__.<<("<div>")
  if foo
    __buffer__.<<("<h1>foo</h1>")
  else
    __buffer__.<<("<h2>bar</h2>")
  end
  __buffer__.<<("</div>")
  __buffer__
}
```

We need to generate a lambda, which we do with #make_lambda, because we need to
prepend the __buffer__ param to the list of lambda params. The body of the
lambda is compiled from the given template AST with compile_html.

```ruby
# @param template [Proc] original template
# @return [Proc] compiled template
def compile(template)
  ast = Sirop.ast(template)
  compiled = Sirop.make_lambda(
    parameters: [:__buffer__, *ast.parameters],
    body: compile_html(ast)
  }
  eval(Sirop.to_source(compiled))
end
```

This is the hard part - how to "mutate" the original AST into the compiled form.
We could do this using a MutationVisitor, which is similar to the current
implementation of Papercraft, but what would be interesting is to see if we can
do this using some kind of DSL that allows us to visit each node in the AST and
either emit it or emit some specialized code:

```ruby
# @param ast [Prism::Node] template body ast
# @return [Prism::Node] compiled ast
def compile_html(ast)
  html_parts = []
  flusher = -> {
    return nil if html_parts.empty?
    
    html = html_parts.join; html_parts.clear
    quote(locals: [:__buffer__]) { __buffer__ << unquote(html) }
  }
  quote(locals: [:__buffer__, *ast.parameters]) {
    unquote(
      ast_transform(ast) { |node, transform|
        if html_tag?(node)
          emit_html(node, transform, html_parts, flusher)
        else
          [flusher.(), *transform.(node)]
        end
      }
    )
    unquote(flusher.() || :__nop__)
    __buffer__
  }
end

def html_tag?(node)
  node.is_a?(Prism::CallNode) && node.receiver.nil? && other_conditions(node)
end

def emit_html(node, transform, html_parts, flusher)
  if node.block?
    emit_html_with_block(node, transform, html_parts, flusher)
  else
    html_parts << format_html_tag(node)
  end
end

def emit_html_with_block(node, transform, html_parts, flusher)
  html_parts << format_html_open_tag(node)
  ast = transform.(node.block)
  html_parts << format_html_close_tag(node)
  ast
end
```

How does quote work?

```ruby
def quote(**opts, &block)
  ast = Sirop.ast(block)

  # the quote_transform will mutate the ast such that any call to unquote inside
  # the block will be replaced with the result of the actual unquote call
  ast_transform(ast, **opts) { |node, transform|
    if unquote_call?(node)
      unquote_value_to_ast(node.parameters[0], transform)
    else
      node
    end
  }
end
```

How does unquote work?

```ruby
# @param v [any] value
# @return [Prism::Node] AST node
def unquote(v)
  case v
  when nil, Prism::Node
    v # if nil is returned, nothing is emitted into the quote block
  else
    to_ast(v)
  end
end

def to_ast(v)
  case v
  when nil
    Prism::NilNode.new(...)
  when true
    Prism::TrueNode.new(...)
  when Integer
    Prism::IntegerNode.new(...)
  # etc...
  end
end
```

Additional tools required:

```ruby
def ast_transform(ast, &block)
  transform = ->(node) { block.(node, transform) }
  block.(ast, transform)
end
```

## ERB compiler

Can we implement an ERB compiler with quote/unquote?

```ruby
TEMPLATE = <<~ERB
  <ul>
    <% @items.each do |i| %>
      <li><%= i %></li>
    <% end %>
  </ul>
ERB

# compiled proc looks like:
-> {
  __buffer__ = +'<ul>'
  @items.each do |i|
    __buffer << "<li>#{i}</li>"
  end
  __buffer << '</ul>'
  __buffer__
}

# @param template [String]
# @return [Proc]
def compile_erb(template)
  parts = TEMPLATE.split(/(\<%\=?.+)%\>/).map(&:strip)
  ast = quote {
    __buffer__ = +''
    unquote(
      parts.map do |p|
        case p
        when m = p.match(/\<%\= (.+)/)
          quote { __buffer__ << "#{unquote_verbatim(m[1])}" }
        when m = p.match(/\<% (.+)/)
          quote { unquote_verbatim(m[1]) }
        else
          quote { __buffer__ << unquote(p) }
        end
      end
    )
    __buffer__
  }
  eval(Sirop.to_source(ast))
end
```

This is a very simple compiler, not at all optimized, but it shows how this
could be done. If we want to buffer html parts and then flush them into
`__buffer__ << ...` expressions, we'll need to employ the technique shown above
for the Papercraft compiler, but this is totally doable.

Additional tools:

```ruby
def unquote_verbatim(str)
  # this could be a bit more complicated, if we need to take into account local vars etc.
  magically_convert_string_to_ast(str)
end
```

## Something like has_many

The Rails implementation of `has_many` is amazingly complex! But finally, it
does get down to a bunch of `eval`s, or rather, `class_eval`:

```ruby
# https://github.com/rails/rails/blob/c9e85dbe297e248dd2f217d04f84a94881ac046a/activerecord/lib/active_record/associations/builder/association.rb#L103
def self.define_readers(mixin, name)
  mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
    def #{name}
      association = association(:#{name})
      deprecated_associations_api_guard(association, __method__)
      association.reader
    end
  CODE
end
```

We need a way to define a method:

```ruby
def define_readers(mixin, name)
  ast = Sirop.make_method(
    name: name,
    parameters: [],
    body: quote {
      association = association(unquote(name))
      deprecated_associations_api_guard(association, __method__)
      association.reader
    }
  )
  mixin.class_eval(Sirop.to_source(ast))
end
```

Actually, Ruby syntax allows us to do the following:

```ruby
def define_readers(mixin, name)
  ast = quote {
    def unquote(name)
      association = association(unquote(name))
      deprecated_associations_api_guard(association, __method__)
      association.reader
    end
  }
  mixin.class_eval(Sirop.to_source(ast))
end
```

While the syntax is a bit confusing, this is exactly how it looks in Elixir:

```elixir
defmacro define_function(name, return_value) do
  # Ensure the name is an atom (e.g., :my_func)
  func_name = String.to_atom("#{name}")

  quote do
    # Unquote `func_name` inside the function header
    def unquote(func_name)() do
      unquote(return_value)
    end
  end
end
```

## Can we do the same for a lambda definition?

Suppose we want to create a lambda with arbitrary parameters (e.g. the
Papercraft compiler):

```ruby
quote {
  ->(__buffer__, unquote(ast.parameters)) { 42 }
}
```

While Prism does parse this, the whole AST looks bizarre and quite distorted,
which may lead to all kinds of problems when trying to transform it back to
source code. We might want to experiment with this, but on the whole, this may
lead to unforseen problems and limitations, and may also significantly
complicate the implementation.

Let's put this aside for the moment, and concentrate on providing simpler tools for defining methods and lambdas:

```ruby
quote {
  def_method(unquote(name), a, b, *, **, &) {
    ...
  }

  def_lambda(__buffer__, unquote(ast.arguments)) {
    ...
  }
}
```

Yeah, that's much clearer, and also simpler to implement.

## Interim summary 1

So, we have the following tools:

- `quote { ... }` (convert given block to ast)
- `unquote(v)` (convert arbitrary value to ast (inside quote))
- `ast_transform(ast) { |node, transformer| ... }` (deep transform ast)

- `unquote_verbatim(str)` (convert given source code to ast)
- `def_method(unquote(name), *params) { ... }` (define method)
- `def_lambda(*params) { ... }` (define lambda)

## What about source locations?

One simple option is to synthesize the AST and also synthesize the location info
of the macro definition:

```ruby
# adder.rb:
def make_adder(v)
  ast = quote {
    ->(x) {
      x + unquote(v)
    }
  }
  eval(ast.to_source, *ast.source_location)
end

adder = make_adder(1)
adder(:a)
#=> BOOM: undefined method '+' ...
# from adder.rb:4:in ...
# from adder.rb:11:in '<main>'
```

At least for a beginning, this should work fine. Eventually, we might want to
cache "rendered" source code with synthetic source locations such as
`(:adder:foo):1', which we might express with:

```ruby
ast = quote(key: 'adder:foo') { ... }
```

## More on the Behaviour of unquote

### unquote(nil)

The above `unquote` implementation behaviour when passed a `nil` is problematic.
We need to be able to inject a nil into the quoted code.

### unquote([...].map { ... })

When calling unquote with an array, we also need to differentiate between an
array of normal values and an array of AST nodes, like in the validator example
above. We can be more explicit about it by providing another tool, e.g.:

```ruby
# implicit (same as validator example above)
def create_validator(*conds)
  # quote returns an AST
  ast = quote {
    ->(v) {
      unquote(
        conds.map { |c| quote { unquote(c) === v } }
      )
      v
    }
  }
  eval(ast.to_source)
end

# explicit
def create_validator(*conds)
  # quote returns an AST
  ast = quote {
    ->(v) {
      unquote_block(
        conds.map { |c| quote { unquote(c) === v } }
      )
      v
    }
  }
  eval(ast.to_source)
end
```

## Interim summary 2

So, we have the following tools:

- `quote { ... }` (convert given block to ast)
- `unquote(v)` (convert arbitrary value to ast (inside quote))
- `ast_transform(ast) { |node, transformer| ... }` (deep transform ast)

- `unquote_verbatim(str)` (convert given source code to ast)
- `unquote_block([...])` (convert given array of nodes to a block node) (???)
- `def_method(unquote(name), *params) { ... }` (define method)
- `def_lambda(*params) { ... }` (define lambda)

## Deep transform of a block (Test example)

Suppose we want to define a test DSL:

```ruby
# taking inspiration from https://zig.guide/getting-started/running-tests/

require 'footest'

test 'always succeeds' {
  expect(true)
}

test 'always fails' {
  expect(false)
}

test 'expression' {
  expect(1  + 1 != 2)
}

# expect an exception
test 'raise' {
  expect_raises(NoMethodError, foo.bar)
}

# regexp
test 'raise' {
  expect 'foobar' =~ /baz/
  expect (m = 'foo'.match(/f(.+)/)) && m[1] == 'oo'
}

# custom expect 
```

With this syntax, we can avoid implementing expect with a block. Instead We need
to intercept the calls to `expect` as follows:

```ruby
def test(name, &block)
  ast = Sirop.ast(block)
  transformed = mutate(ast) { |node, transform|
    if node in Prism::CallNode, receiver: nil, name: :expect, arguments:)
      quote { assert { unquote(arguments[0]) } }
    else
      transform.(node)
    end
  }
  test_case = Testing::TestCase.new(name, eval_ast(transformed))
end
```

So here we add an `ast_match` Gtool for matching a node by type and by arbitrary
properties, but we can also use pattern matching, which Prism already supports:

```ruby
ast_transform(ast) { |node, transform|
  case node
  in Prism::CallNode(receiver: nil, name: :expect, arguments: [expr, *])
    quote { test.assert { unquote(node.arguments[0]) } }
  else
    transform.(node)
  end
}
```

So, actually no need to have our own tool, just use regular pattern matching.

## Generating code and saving it

Rails generators use ERB templates, here's an excerpt:

```erb
class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :<%= table_name %><%= render_table_with_dom_id %> do |t|
<% attributes.each do |attribute| -%>
<% if attribute.password_digest? -%>
      t.string :password_digest<%= attribute.inject_options %>
<% elsif attribute.token? -%>
      t.string :<%= attribute.name %><%= attribute.inject_options %>
<% else -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
<% end -%>
<% end -%>
<% if options[:timestamps] -%>
      t.timestamps
<% end -%>
    end
  end
end
```

How would it look with quote/unquote?

```ruby
version = ActiveRecord::Migration.current_version
ast = quote do
  def_class(unquote(migration_class_name), ActiveRecord::Migration[unquote(version)]) do
    def change
      create table unquote(table_name) do |t|
        unquote attributes.map do |attribute|
          opts = attribute.inject_options
          if attribute.password_digest?
            quote { t.string unquote(:"password_digest#{opts}") }
          elsif attribute.token?
            quote { t.string unquote(:"#{attribute.name}#{opts}") }
          else
            # note use of unquote as method name
            quote { t.send(unquote(attribute.type), unquote(:"#{opts}") }
          end
        end
        unquote(
          options[:timestamps] ? quote { t.timestamps } : :__nop__
        )
      end
    end
  end
end

IO.write(fn, Sirop.to_source(ast))
```

## Class/module definitions

Actually, Prism does accept class definitions in the form:

```ruby
class unquote(c) < A::B::unquote(1)
  def x; 1; end
end
```

But it fucks up syntax highlighting, at least in Zed, so we'll probably want to
have `def_class` and `def_module`.

## The nil problem revisited

In order to allow `unquote` to emit nothing, we introduce the `:__nop__` value,
which lets us conditionally emit code. Quick recap: unquote is evaluated at
compile time, while the surrounding quoted code is evaluated at run time. So
unquote allows us to conditionally generate code. Using `:__nop__` allows us to
treat nil as a normal value.

```ruby
def gen(x, print)
  ast = quote {
    unquote(
      print ? quote { puts "Adding to #{unquote(x)}" } : :__nop__
    )
    x + 1
  }
end
```

## Interim summary 3

So, we have the following tools:

- `quote { ... }` (convert given block to ast)
- `unquote(v)` (convert arbitrary value to ast (inside quote))
- `ast_transform(ast) { |node, transformer| ... }` (deep transform ast)
- `:__nop__` special value for emitting nothing

- `unquote_verbatim(str)` (convert given source code to ast)
- `unquote_block([...])` (convert given array of nodes to a block node) (???)

- `def_class(class_name, base_class = nil) { ... }` (define class)
- `def_module(module_name) { ... }` (define module)
- `def_method(unquote(name), *params) { ... }` (define method)
- `def_lambda(*params) { ... }` (define lambda)

Remarks and observations:

- `unquote` is eavaluated at macro compile time, which lets us generate code
  conditionally.
- `unquote_block` can be used to transform any enumerable into a block of code.
  Here, too, we may use `:__nop__`:

  ```ruby
  quote {
    unquote_block items.map { |i|
      i.show? ? quote { t.send(unquote(i.to_sym), true) } : :__nop__
    }
  }
  ```

## unquoting a method call

In the above last example, we want to generate a method call based on some
unquoted value. We need a tool for doing this:

```ruby
quote {
  # instead of
  t.send(unquote(m), *, **, &)

  # do this
  t.__call__(unquote(m), *, **, &)
}
```

## Interim summary 4

So, we have the following tools:

- `quote { ... }` (convert given block to ast)
- `unquote(v)` (convert arbitrary value to ast (inside quote))
- `ast_transform(ast) { |node, transformer| ... }` (deep transform ast)
- `:__nop__` special value for emitting nothing

- `unquote_verbatim(str)` (convert given source code to ast)
- `unquote_block([...])` (convert given array of nodes to a block node) (???)

- `o.__call__(m, *, **, &)` (method call with arbitrary method name)
- `def_class(class_name, base_class = nil) { ... }` (define class)
- `def_module(module_name) { ... }` (define module)
- `def_method(unquote(name), ...) { ... }` (define method)
- `def_lambda(*params) { ... }` (define lambda)

Remarks and observations:

- `unquote` is eavaluated at macro compile time, which lets us generate code
  conditionally.
- `unquote_block` can be used to transform any enumerable into a block of code.
  Here, too, we may use `:__nop__`:

  ```ruby
  quote {
    unquote_block items.map { |i|
      i.show? ? quote { t.__call__(unquote(i.name), true) } : :__nop__
    }
  }
  ```

## Enhancing methods

Suppose we want to be able to automagically memoize arbitrary methods.

The traditional approach would be something like:

```ruby
# by defining a module (should work, but check it)
module Memoize
  def memoize(*methods)
    mod = Module.new
    methods.each do |m|
      mod.define_method(m) { (@memo ||= {})[m] ||= super }
    end
    prepend(mod)
  end
end
```

With quote/unqoute:

```ruby
module Memoize
  def memoize(*methods)
    methods.each do |m|
      ast = Sirop.to_ast(method(m))
      # in place mutation (can we make this work?)
      # Sirop.mutate(root, node => replacement, ...)
      memoized = Sirop.mutate(
        ast,
        ast.body => quote { (@memo ||= {})[m] = (unqoute(ast.body)) }
      )
      eval(Sirop.to_source(memoized))
    end
  end
end
```

## Mutating an AST

We introduce `#mutate` method which are used to do a deep transform.

```ruby
# mutate with a block
l1 = ->(x) { 42 }
l2 = Sirop.eval self, Sirop.mutate(Sirop.to_ast(l1)) { |n|
  n.is_a?(Prism::IntegerNode) ? quote { 43 } : n
}

# mutate with node replacement hash
ast = Sirop.to_ast(method(:foo))
Sirop.eval self, Sirop.mutate(
  ast, ast.body => quote {
    (@memo ||= {})[m] = (unqoute(ast.body))
  }
)
```

Added tools:

- `Sirop.eval(receiver, ast)` - eval the given ast on the given receiver
- `Sirop.mutate(ast) { ... }` - copy the ast, replacing nodes with the result of
  the block
- `Sirop.mutate(ast, n1 => n2)` - copy the ast, replacing nodes with given
  replacements

## RoutingTree

```ruby
# from routing_tree.rb
def emit_wildcard_childless_root_code(buffer, root_path)
  emit_code_line(buffer, '->(path, params) {')
  if root_path != '/'
    re = /^#{Regexp.escape(root_path)}(\/.*)?$/
    emit_code_line(buffer, "  return if path !~ #{re.inspect}")
  end
  emit_code_line(buffer, "  @dynamic_map[#{root_path.inspect}]")
  emit_code_line(buffer, '}')
end
```

What about:

```ruby
def emit_wildcard_childless_root_code(root_path)
  re = /^#{Regexp.escape(root_path)}(\/.*)?$/
  quote {
    ->(path, params) {
      unquote(
        root_path != '/' ?
          quote { return if path != unquote(re) }) : :__nop__        
      )
      dynamic_map[unquote(root_path)]
    }
  }
end
```

Further on:

```ruby
def visit_routing_tree_entry(entry:, segment_idx:)
  # If no targets exist in the entry's subtree, we can return nil
  # immediately.
  if !entry[:target] && !find_target_in_subtree(entry)
    return quote { nil }
  end

  if void_route?(entry)
    parent = entry[:parent]
    parametric_sibling = parent && parent[:children] && parent[:children]['[]']
    if parametric_sibling
      return quote { nil }
    end
  end

  return :__nop__ if !entry[:target] && !entry[:children]

  if entry[:target] && entry[:handle_subtree] && !entry[:children]
    if entry[:static] ?
      quote { return @static_map[unquote(entry[:path])] } :
    else
      quote { return @dynamic_map[unquote(entry[:path])] }
    end
  end

  clauses = []
  if entry[:target]
    return_expr = entry[:static] ?
      quote { return @static_map[unquote(entry[:path])] } :
      quote { return @dynamic_map[unquote(entry[:path])] }
    clauses << quote { when nil; unquote(return_expr) }
  end
  if entry[:children]
    clauses << routing_tree_entry_children_clauses(clauses, entry:, segment_idx:)
  end

  # Get next segment
  if !clauses.empty?
    quote {
      case (s = segments[unquote(segment_idx)])
        unquote()
      end
    }
  end
end
```

There are two problems with this, related to how case is parsed. Prism cannot
parse an isolated "when foo" expression. It also can't parse "case x;
unquote(y); end", so we need a way to express this. Maybe:

```ruby
quote {
  __.case(foo) {
    __.when nil
      return nil
    __.else {
      __.case
    }
  }
}
```

OK, this looks OK for what it does. But can we take it further?

```ruby
quote {
  __.case(foo) {
    unquote clauses.map { quote {
      __.when(nil) {
        return nil
      }
    }}
    __.else
      unquote {
        if entry[:is_static]
          quote { __.return @static_map['/foo/bar'] }
        else
          quote { __.return @dynamic_map['/foo/bar'] }
        end
      }
  }
}
```

## The binding problem

We have a big problem:

```ruby
def unroll_loop(range, &block)
  quote {
    unquote {
      range.map { |v|
        quote { block.(unquote(v)) }
      }
    }
  }
end
```

The quoted block is not `eval`ed. The block given to unquote is reified from the
AST and then `eval`ed. The problem here is that when `eval`ing the unquoted
block, we don't have access to the binding of `unroll_loop`, since we're running
in the context of a `quote` call. This is the famous "binding of caller"
problem.

A solution would be to explicitly pass the binding to quote:

```ruby
quote(binding) { ... }
```

This allows us to do this, and the syntax cost is negligible. This is good
enough.

## Interim summary 5

Again, the basic tools:

- `quote(?binding) { }`
- `unquote(v)` / `unquote { }`
- `mutate(v)` / `mutate { }`

Source <-> AST:

- `Sirop.to_ast(o)`
- `Sirop.to_source(ast)`
- `eval_ast(ast)`

Synthetic code:

- `__.case(e) { }`/`__.when(e) { }`/`__.if(e) { }` etc.
- `__.def(m, *args) { }`
- `__.lambda(*args) { }`
- `__.(m, *args)` - a synthetic call
- `receiver.__.(m, *args)` - synthetic call with receiver
- `__.begin { }` / `__.rescue(E => e) { }` / `__.ensure { }` etc.

## Implementing something like `__.case`

```ruby
def synthetic_case(expr_ast, body_ast)
  # using the Prism DSL
  Prism::CaseNode(value: expr_ast, body: body_ast, ...)
end

# some are easier:
def synthetic_begin(body_ast)
  quote(binding) { begin { unquote(body_ast) } }
end
```

## The question of backtraces

Since we're generating a synthetic AST, which may be compose of ASTs originating
in different source locations, how can we reflect the true location of each part
of the generated code?

One solution is to just do what tools like ERB or IRB do, and report the
filename as `(sirop)`.

A second solution is to add a `begin/rescue` and translate the backtrace
accordingly, but this solution may prove to be brittle, and inexact.
