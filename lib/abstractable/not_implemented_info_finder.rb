require "abstractable"
require "abstractable/pedigree_stream"

module Abstractable
  # this class can find to information of unimplemented abstract method
  class NotImplementedInfoFinder
    # find(klass) -> hash
    #
    # Returns an hash as information of unimplemented abstract method.
    # hash format is {class => array of unimplemented method in class, ... }
    def find(klass)
      find_from_pedigree_stream(PedigreeStream.new(klass))
    end

    # find_from_singleton(klass) -> hash
    # singleton_class version find.
    def find_from_singleton(klass)
      find_from_pedigree_stream(SingletonPedigreeStream.new(klass))
    end

    private

    def find_from_pedigree_stream(pedigree_stream)
      pedigree_stream.each_with_descendants_and_object(create_deny_empty_array_hash) do |klass, descendants, hash|
        hash[klass] = find_from_ancestor_and_descendants(klass, descendants) if need_find?(klass, descendants)
      end
    end

    def create_deny_empty_array_hash
      hash = {}
      def hash.[]=(key, value)
        super(key, value) unless value.empty?
      end
      hash
    end

    def need_find?(ancestor, descendants)
      ancestor.is_a?(Abstractable) && 0 < descendants.size
    end

    def find_from_ancestor_and_descendants(ancestor, descendants)
      ancestor.abstract_methods(false).reject { |method| descendants.any?(&individual_method_defined?(method)) }
    end

    def individual_method_defined?(method)
      lambda { |klass| klass.instance_methods(false).include? method }
    end
  end
end
