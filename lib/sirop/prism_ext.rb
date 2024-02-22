# frozen_string_literal: true

require 'prism'

class Prism::BasicVisitor
  def on(type, &)
    singleton_class.define_method(:"visit_#{type}_node", &)
    self
  end
end
