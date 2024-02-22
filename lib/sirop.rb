# frozen_string_literal: true

require 'prism'
require 'sirop/proc_finder'
require 'sirop/method_finder'
require 'sirop/rewriter'

module Sirop
  class << self
    def find(obj)
      case obj
      when Proc
        find_proc(obj)
      when UnboundMethod, Method
        find_method(obj)
      else
        raise ArgumentError, "Invalid object type"
      end
    end

    def to_source(node)
      Rewriter.new.rewrite(node)
    end

    def to_string(obj)
      to_source(find(obj))
    end

    private

    def find_proc(proc)
      fn, lineno = proc.source_location  
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value
    
      finder = Sirop::ProcFinder.new(proc, lineno)
      finder.find(program)
    end

    def find_method(method)
      fn, lineno = method.source_location
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value
    
      finder = Sirop::MethodFinder.new(method, lineno)
      finder.find(program)
    end
  end
end
