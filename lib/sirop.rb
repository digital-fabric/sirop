# frozen_string_literal: true

require 'prism'
require 'sirop/prism_ext'
require 'sirop/finder'
require 'sirop/sourcifier'

module Sirop
  class << self
    def to_ast(obj)
      case obj
      when Proc
        proc_ast(obj)
      when UnboundMethod, Method
        method_ast(obj)
      else
        raise ArgumentError, "Invalid object type"
      end
    end

    def to_source(obj)
      obj = to_ast(obj) if !obj.is_a?(Prism::Node)
      Sourcifier.new.to_source(obj)
    end

    # def to_string(obj)
    #   to_source(to_ast(obj))
    # end

    private

    def proc_ast(proc)
      fn, lineno = proc.source_location  
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value

      Finder.find(program, proc) do
        on(:lambda) do |node|
          found!(node) if node.location.start_line == lineno
          super(node)
        end
        on(:call) do |node|
          case node.name
          when :proc, :lambda
            found!(node) if node.block && node.block.location.start_line == lineno
          end
          super(node)
        end
      end
    end

    def method_ast(method)
      fn, lineno = method.source_location
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value

      Finder.find(program, method) do
        on(:def) do |node|
          found!(node) if node.name == method.name && node.location.start_line == lineno
          super(node)
        end
      end
    end
  end
end
