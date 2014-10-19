module Abstractable
  # this class represent stream of pedigree to myself from an ancestor.
  class PedigreeStream
    include Enumerable

    def initialize(klass)
      fail ArgumentError, "wrong type argument #{klass} (should be Class) " unless klass.is_a? Class
      self.pedigree_stream = pedigree_stream_of(klass)
    end

    # each for Enumerable.
    def each
      pedigree_stream.each { |klass| yield klass }
    end

    # each with descendants
    #
    # Example of use:
    # each_with_descendants do |klass, descendants_of_klass|
    #   your code...
    # end
    def each_with_descendants
      each do |klass|
        yield(klass, descendants_of(klass))
      end
    end

    # each_with_object with descendants.
    #
    # Example of use:
    # each_with_descendants_and_object([]) do |klass, descendants_of_klass, array|
    #   your code...
    # end
    def each_with_descendants_and_object(object)
      each_with_descendants do |klass, descendants_of_klass|
        yield(klass, descendants_of_klass, object)
      end
      object
    end

    # descendants_of(klass) -> array
    # Returns an array of descendants name of class.
    def descendants_of(klass)
      i = pedigree_stream.index(klass)
      i ? pedigree_stream.drop(i + 1) : []
    end

    protected

    attr_accessor :pedigree_stream

    def pedigree_stream_of(klass)
      klass.ancestors.reverse
    end
  end

  # PedigreeStream of Singleton Class.
  class SingletonPedigreeStream < PedigreeStream
    def pedigree_stream_of(klass)
      klass.ancestors.reverse.map(&:singleton_class)
    end
  end
end
