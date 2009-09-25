require 'dm-counter-cache/version'

module DataMapper
  module CounterCacheable
    
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      # override to support counter caching
      def belongs_to(name, *args)
        options = args.last.kind_of?(Hash) ? args.last : {}
        
        # wrap the belongs_to call
        counter_cache_attribute = options.delete(:counter_cache)
        relationship = super
        setup_counter_cache_attribute(counter_cache_attribute, relationship) if counter_cache_attribute

        relationship
      end
    
      def setup_counter_cache_attribute(counter_cache_attribute, relationship)
        case counter_cache_attribute
          when String, Symbol
            counter_cache_attribute = counter_cache_attribute.to_s
          else
            counter_cache_attribute = "#{relationship.source_model.storage_name}_count".to_s
        end
                
        relationship.source_model.class_eval <<-EOS, __FILE__, __LINE__            
          unless method_defined?(:increment_counter_cache_for_#{relationship.name})
            after :create, :increment_counter_cache_for_#{relationship.name}
            after :destroy, :decrement_counter_cache_for_#{relationship.name}
    
            def increment_counter_cache_for_#{relationship.name}
              return unless ::#{relationship.parent_model}.properties.named?(:#{counter_cache_attribute})
              if self.#{relationship.name} && self.class == #{relationship.source_model.name}
                self.#{relationship.name}.update(:#{counter_cache_attribute} => self.#{relationship.name}.reload.#{counter_cache_attribute}.succ)
              end
            end
    
            def decrement_counter_cache_for_#{relationship.name}
              return unless ::#{relationship.parent_model}.properties.named?(:#{counter_cache_attribute})
              if self.#{relationship.name} && self.class == #{relationship.source_model.name}
                self.#{relationship.name}.update(:#{counter_cache_attribute} => self.#{relationship.name}.reload.#{counter_cache_attribute} - 1)
              end
            end
          end
    
        EOS
        
      end
    end
  end
end