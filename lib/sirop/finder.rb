# frozen_string_literal: true

require 'prism'

module Sirop
  class Finder < Prism::BasicVisitor
    def self.find(*, &)
      finder = self.new
      finder.find(*, &)
    end

    def find(root, key, &)
      instance_exec(&)
      @key = key
      catch(key) do
        visit(root)
        nil
      end
    end

    def found!(node)
      throw(@key, node)
    end

    def method_missing(sym, node, *args)
      visit_child_nodes(node)
    end
  end
end
