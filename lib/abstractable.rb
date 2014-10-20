require "abstractable/version"
require "abstractable/not_implemented_info_finder"

# abstract method support module.
module Abstractable
  class WrongOperationError < StandardError; end

  def included(base)
    base.extend(Abstractable)
  end

  # new after unimplemented abstract methods validation.
  def new(*args, &block)
    validate_on_create(:new)
    super(*args, &block)
  end

  # allocate after unimplemented abstract methods validation.
  def allocate(*args, &block)
    validate_on_create(:allocate)
    super(*args, &block)
  end

  # Define abstract methods.
  #
  # Example:
  #   abstract :execute           # one symbol
  #   abstract :method1, :method2 # multiple symbol
  #   # in block
  #   abstract do
  #     def method3; end
  #     def method4; end
  #   end
  def abstract(*names, &block)
    add_abstract_methods(*names.compact)
    add_abstract_methods_by_block(&block) if block_given?
  end

  # abstract_methods(all=true)   -> array
  #
  # Returns an array containing the names of abstract methods in the receiver.
  # if set true to args include ancestors abstract methods.
  # (default true)
  #
  def abstract_methods(all = true)
    do_abstract_methods(all, self, (ancestors - [self]))
  end

  # abstract_singleton_methods(all=true)   -> array
  #
  # Returns an array containing the names of abstract methods in the receivers singleton class.
  # if set true to args include ancestor singleton classes abstract methods.
  # (default true)
  #
  def abstract_singleton_methods(all = true)
    do_abstract_methods(all, singleton_class, (ancestors - [self]).map(&:singleton_class))
  end

  # Unimplemented abstract methods validation.
  #
  # if found unimplemented methods then throw NotImplementedError.
  def validate_not_implemented_abstract_methods
    not_impl_info = Abstractable.find_not_implemented_info(self)
    fail NotImplementedError, build_error_message(not_impl_info) unless not_impl_info.empty?
    @implemented_abstract_methods = abstract_methods
  end

  # required_validate? -> true or false
  #
  # Returns <code>true</code> if required unimplemented abstract methods validation.
  #
  # if validated or if defined environment variable  <code>ABSTRACTABLE_IGNORE_VALIDATE</code>
  # then always return true.
  def required_validate?
    !ENV["ABSTRACTABLE_IGNORE_VALIDATE"] && @implemented_abstract_methods != abstract_methods
  end

  # Shortcut to NotImplementedInfoFinder.new.find(klass)
  def self.find_not_implemented_info(klass)
    NotImplementedInfoFinder.new.find(klass)
  end

  # Shortcut to NotImplementedInfoFinder.new.find_from_singleton(klass)
  def self.find_not_implemented_info_from_singleton(klass)
    NotImplementedInfoFinder.new.find_from_singleton(klass)
  end

  private

  def individual_abstract_methods
    @individual_abstract_methods ||= []
  end

  def do_abstract_methods(all = true, klass, ancestors_of_klass)
    result = []
    individual_abstract_methods_reader = lambda { |clazz| clazz.class_eval { individual_abstract_methods } }
    if klass.is_a? Abstractable
      result.push(*individual_abstract_methods_reader.call(klass))
      return result unless all
    end
    ancestors_of_klass.each_with_object(result) do |ancestor, array|
      array.push(*individual_abstract_methods_reader.call(ancestor)) if ancestor.is_a? Abstractable
    end
  end

  def validate_on_create(create_method_name)
    validate_not_implemented_abstract_methods if required_validate?
    if is_a?(Abstractable) && 0 < abstract_methods(false).size
      fail WrongOperationError, "#{self} has abstract methods. and therefore can't call #{create_method_name}."
    end
  end

  def build_error_message(not_implemented_infos)
    messages = ["following abstract methods are not implemented."]
    formatter = Proc.new { |klass, methods| "#{methods} defined in #{klass}" }
    messages.push(*not_implemented_infos.map(&formatter)).join("\n")
  end

  def define_abstract_skeleton(method)
    this = self
    class_eval do
      define_method method do |*_|
        fail NotImplementedError, "#{method} is abstract method defined in #{this}, and must implement."
      end
    end
  end

  def add_abstract_methods_by_block(&block)
    old_instance_methods = instance_methods(false)
    block.call
    add_abstract_methods(*(instance_methods(false) - old_instance_methods))
  end

  def add_abstract_methods(*methods)
    methods.each { |method| add_abstract_method(method) }
  end

  def add_abstract_method(method)
    fail ArgumentError, "wrong type argument #{method} (should be Symbol) " unless method.is_a? Symbol
    individual_abstract_methods << method
    define_abstract_skeleton(method)
  end

  # called when the method is undef.
  def method_undefined(method)
    individual_abstract_methods.delete(method)
  end
end
