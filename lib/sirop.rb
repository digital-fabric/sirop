# frozen_string_literal: true

require 'prism'
require 'sirop/proc_finder'
require 'sirop/method_finder'
require 'sirop/rewriter'

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

    def to_source(node)
      Rewriter.new.rewrite(node)
    end

    def to_string(obj)
      to_source(to_ast(obj))
    end

    private

    def proc_ast(proc)
      fn, lineno = proc.source_location  
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value
    
      finder = Sirop::ProcFinder.new(proc, lineno)
      finder.find(program)
    end

    def method_ast(method)
      fn, lineno = method.source_location
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value
    
      finder = Sirop::MethodFinder.new(method, lineno)
      finder.find(program)
    end
  end
end
