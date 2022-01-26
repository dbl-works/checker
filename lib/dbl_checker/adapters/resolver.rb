# get anything that responds to `call` from a given adapter
module DBLChecker
  module Adapters
    module Resolver
      class << self
        def call(adapter)
          return adapter.instance if singelton_method?(adapter)
          return adapter.new if instance_method?(adapter)
          return adapter if klass_method?(adapter)

          raise DBLChecker::Errors::ConfigError, 'Unknown or invalid adapters configured.'
        end

        def singelton_method?(adapter)
          class_or_module?(adapter) &&
            adapter.ancestors.include?(Singleton) &&
            adapter.instance.methods.include?(:call)
        end

        def klass_method?(adapter)
          class_or_module?(adapter) &&
            adapter.methods.include?(:call)
        end

        def instance_method?(adapter)
          class_or_module?(adapter) &&
            adapter.respond_to?(:new) &&
            adapter.new.methods.include?(:call)
        end

        def class_or_module?(adapter)
          adapter.is_a?(Class) || adapter.is_a?(Module)
        end
      end
    end
  end
end
