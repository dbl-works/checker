# check if a strategy for persistance or fetching job executions
# has a `call` method either as singleton, class, or instance method
module DBLChecker
  module Adapters
    module Validator
      class << self
        def call(strategy)
          return false unless strategy.is_a?(Class) || strategy.is_a?(Module)

          singelton_method?(strategy) ||
            klass_method?(strategy) ||
            instance_method?(strategy)
        end

        def singelton_method?(strategy)
          strategy.ancestors.include?(Singleton) &&
            strategy.instance.methods.include?(:call)
        end

        def klass_method?(strategy)
          strategy.methods.include?(:call)
        end

        def instance_method?(strategy)
          strategy.respond_to?(:new) &&
            strategy.new.methods.include?(:call)
        end
      end
    end
  end
end
