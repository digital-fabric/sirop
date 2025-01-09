# frozen_string_literal: true

require 'prism'

class Prism::BasicVisitor
  def on(type, &)
    singleton_class.define_method(:"visit_#{type}_node", &)
    self
  end
end

class Prism::ParametersNode
  attr_accessor :injected_prefix
end

class Prism::BlockParametersNode
  attr_accessor :injected_parameters
end

class Prism::LambdaNode
  attr_reader :after_body_proc

  # @param params [String] injected parameters
  # @return [void]
  def inject_parameters(params)
    if parameters
      if parameters.parameters
        parameters.parameters.injected_prefix = Sirop::Injection.new(params)
      else
        parameters.injected_parameters = Sirop::Injection.new(params)
      end
    else
      instance_variable_set(:@parameters, Sirop::Injection.new("(#{params})"))
    end
  end

  def after_body(&b)
    @after_body_proc = b
  end
end
