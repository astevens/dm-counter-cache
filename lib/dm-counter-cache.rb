require 'dm-counter-cache/version'

module DataMapper
  module CounterCacheable
    
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end


    def counter_cache_attribute(counter_cache_attribute_or_boolean)
      case counter_cache_attribute_or_boolean
        when String, Symbol
          counter_cache_attribute_or_boolean
        else
          "#{self.class.storage_name}_count"          
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


      def setup_counter_cache_attribute(attribute_name, relationship)
        relationship.source_model.class_eval <<-EOS, __FILE__, __LINE__
          unless method_defined?(:increment_counter_cache_for_#{relationship.name})
            before :update,  :update_counter_cache_for_#{relationship.name}
            after :create, :increment_counter_cache_for_#{relationship.name}
            after :destroy, :decrement_counter_cache_for_#{relationship.name}

            def update_counter_cache_for_#{relationship.name}
              counter_cache_attribute = counter_cache_attribute(#{attribute_name.inspect})
              return unless ::#{relationship.parent_model}.properties.named?(counter_cache_attribute)
              if self.#{relationship.name} && self.class == #{relationship.source_model.name} && original_parent = self.original_attributes.detect {|key, _| key.name == :#{relationship.name} }
                self.#{relationship.name}.update(counter_cache_attribute => self.#{relationship.name}.reload.send(counter_cache_attribute) + 1)
                original_parent = original_parent[1]
                original_parent.update(counter_cache_attribute => original_parent.send(counter_cache_attribute) -1 )
              end
            end


            def increment_counter_cache_for_#{relationship.name}
              counter_cache_attribute = counter_cache_attribute(#{attribute_name.inspect})
              return unless ::#{relationship.parent_model}.properties.named?(counter_cache_attribute)
              if self.#{relationship.name} && self.class == #{relationship.source_model.name}
                self.#{relationship.name}.update(counter_cache_attribute => self.#{relationship.name}.reload.send(counter_cache_attribute) + 1)
              end
            end
    
            def decrement_counter_cache_for_#{relationship.name}
              counter_cache_attribute = counter_cache_attribute(#{attribute_name.inspect})
              return unless ::#{relationship.parent_model}.properties.named?(counter_cache_attribute)
              if self.#{relationship.name} && self.class == #{relationship.source_model.name}
                self.#{relationship.name}.update(counter_cache_attribute => self.#{relationship.name}.reload.send(counter_cache_attribute) - 1)
              end
            end
          end
    
        EOS
        
      end
    end
  end
end