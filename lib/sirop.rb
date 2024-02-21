# frozen_string_literal: true

require 'prism'
require 'sirop/block_finder'
require 'sirop/rewriter'

module Sirop
  class << self
    def find(obj)
      case obj
      when Proc
        find_proc(obj)
      else
        raise ArgumentError, "Invalid object type"
      end
    end

    def to_source(node)
      r = Rewriter.new
      r.visit(node)
      r.buffer
    end

    private

    def find_proc(proc)
      fn, lineno = proc.source_location  
      pr = Prism.parse(IO.read(fn), filepath: fn)
      program = pr.value
    
      finder = Sirop::BlockFinder.new(proc, lineno)
      finder.find(program)
    end
  end
end
