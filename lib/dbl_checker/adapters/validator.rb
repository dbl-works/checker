# check if an adapter class/module for persistance or fetching job executions
# has a `call` method either as singleton, class, or instance method
module DBLChecker
  module Adapters
    module Validator
      class << self
        def call(adapter)
          return false unless adapter.is_a?(Class) || adapter.is_a?(Module)

          singelton_method?(adapter) ||
            klass_method?(adapter) ||
            instance_method?(adapter)
        end

        def singelton_method?(adapter)
          adapter.ancestors.include?(Singleton) &&
            adapter.instance.methods.include?(:call)
        end

        def klass_method?(adapter)
          adapter.methods.include?(:call)
        end

        def instance_method?(adapter)
          adapter.respond_to?(:new) &&
            adapter.new.methods.include?(:call)
        end
      end
    end
  end
end
