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

    module ParentMethods
      def increment_counter_cache(attribute)
        return unless self.class.properties.named?(attribute)
        self.send("#{attribute}=", self.send(attribute) + 1)
        save
      end

      def decrement_counter_cache(attribute)
        return unless self.class.properties.named?(attribute)
        self.reload.send("#{attribute}=", self.reload.send(attribute) - 1)
        save
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
        relationship.source_model.class_eval do
          unless method_defined?("increment_counter_cache_for_#{relationship.name}")
            before :update,  "update_counter_cache_for_#{relationship.name}"
            after  :create,  "increment_counter_cache_for_#{relationship.name}"
            after  :destroy, "decrement_counter_cache_for_#{relationship.name}"

            define_method "update_counter_cache_for_#{relationship.name}" do
              if self.send(relationship.name) && original_parent = self.original_attributes.detect {|key, _| key.name == :"#{relationship.name}" }
                self.send(relationship.name).increment_counter_cache(counter_cache_attribute(attribute_name))
                original_parent[1].decrement_counter_cache(counter_cache_attribute(attribute_name))
              end
            end


            define_method "increment_counter_cache_for_#{relationship.name}" do
              self.send(relationship.name).increment_counter_cache(counter_cache_attribute(attribute_name))
            end

            define_method "decrement_counter_cache_for_#{relationship.name}" do
              self.send(relationship.name).decrement_counter_cache(counter_cache_attribute(attribute_name))
            end
          end

        end

        relationship.parent_model.send(:include, ParentMethods)
      end
    end
  end
end