# frozen_string_literal: true

module Sirop
  class Injection
    attr_reader :slice

    def initialize(slice)
      @slice = slice
    end
  end
end
