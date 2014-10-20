# Abstractable

[![Build Status](http://img.shields.io/travis/pujoheadsoft/abstractable.svg)][travis]
[![Coverage Status](http://img.shields.io/coveralls/pujoheadsoft/abstractable.svg)][coveralls]
[![Code Climate](http://img.shields.io/codeclimate/github/pujoheadsoft/abstractable.svg)][codeclimate]

[travis]: http://travis-ci.org/pujoheadsoft/abstractable
[coveralls]: https://coveralls.io/r/pujoheadsoft/abstractable
[codeclimate]: https://codeclimate.com/github/pujoheadsoft/abstractable

## Overview
Abstractable is Library for define abstract method.  
Can know unimplemented abstract methods by fail fast as possible.  
This mechanism is very useful for prevent the implementation leakage.
```ruby
require "abstractable"
class AbstractDriver
  extend Abstractable
  abstract :open, :close
end

class AbstractIODriver < AbstractDriver
  abstract :read, :write
end

class NotImplIODriver < AbstractIODriver; end

NotImplIODriver.new
# => following abstract methods are not implemented. (NotImplementedError)
#    [:open, :close] defined in AbstractDriver
#    [:read, :write] defined in AbstractIODriver
```
See sample above. error occurred at call *new* method.  
Info of unimplemented abstract method have been included in the error message.

## Installation
    gem install abstractable

## How to use
First, call *require "abstractable"*.  
Then, *extend Abstractable*.
```ruby
require "abstractable"
class AbstractClass
  extend Abstractable
end
```
**Note:** This document omit the *require "abstractable"* from now on.

### Define abstract method

1. **Specify *Symbol* (can specify multiple)**
    ```ruby
    class AbstractList
      extend Abstractable

      abstract :add, :insert, :empty?
    end
    ```
    If want to express the arguments then can write be as follows.
    ```ruby
    class AbstractList
      extend Abstractable

      def add(value); end
      def insert(index, value); end
      def empty?; end

      abstract :add, :insert, :empty?
    end
    ```
2. **In block**  
    Defined methods in block is all treated as an abstract method.
    ```ruby
    class AbstractList
      extend Abstractable

      abstract do
        def add(value); end
        def insert(index, value); end
        def empty?; end
      end
    end
    ```
    Can also be written as follows.
    ```ruby
    class AbstractList
      extend Abstractable

      abstract { def add(value); end }
      abstract { def insert(index, value); end }
      abstract { def empty?; end }
    end
    ```

### Get defined abstract methods
*abstract_methods* returns an array containing the names of abstract methods in the receiver.  
 if set *true* to args include ancestors abstract methods (default *true*).
```ruby
class AbstractDriver
  extend Abstractable
  abstract :open, :close
end

class AbstractIODriver < AbstractDriver
  abstract :read, :write
end

AbstractIODriver.abstract_methods # => [:read, :write, :open, :close]
```
If specify *false* for the argument, only abstract methods defined in the receiver is returned.
```ruby
AbstractIODriver.abstract_methods(false) # => [:read, :write]
```
### Undefine of abstract method
Can undefine and if you call *Module#undef_method*.  
However, the receiver must be a class that defines an abstract method.  
(Can't be undefine of the abstract methods of the parent class from a subclass.)
```ruby
class Parent
  extend Abstractable
  abstract :greet
end

class Child < Parent
  undef_method :greet
end

begin
  Child.new # => NotImplementedError
rescue NotImplementedError
end

class Parent
  undef_method :greet
end

Child.new # => OK
```
### Validation of unimplemented abstract method do always called?
Once you have confirmed that the unimplemented methods do not exist, validation does not take place.  
if defined abstract method later, then perform validation once more.  
*required_validate?* returns true if required unimplemented abstract methods validation.
```ruby
class AbstractParent
  extend Abstractable
  abstract :greet
end

class Child < AbstractParent
  def greet; end
end

Child.required_validate? # => true
Child.new
Child.required_validate? # => false

# define abstract method
AbstractParent.abstract :execute

Child.required_validate? # => true
```
#### If define environment variable *ABSTRACTABLE_IGNORE_VALIDATE*
This case is *required_validate?* returns true always.  
*ABSTRACTABLE_IGNORE_VALIDATE* value allow any value.
```
# Linux
export ABSTRACTABLE_IGNORE_VALIDATE=true
# windows
set ABSTRACTABLE_IGNORE_VALIDATE=true
```
### Abstract method of singleton class
Abstract method of singleton class can't validation at new.  
Therefore throw error at abstract method call.  
But can find unimplemented abstract methods.
```ruby
class AbstractParent
  class << self
    extend Abstractable
    abstract :greet
  end
end

class Child < AbstractParent
end

Child.greet # => greet is abstract method defined in
            # #<Class:AbstractParent>, and must implement.
            # (NotImplementedError)
```
### Do explicitly validation
if call *validate_not_implemented_abstract_methods* then can do explicitly validation.
```ruby
class AbstractParent
  extend Abstractable
  abstract :greet
end

class Child < AbstractParent; end

# explicitly validation
Child.validate_not_implemented_abstract_methods
# => following abstract methods are not implemented. (NotImplementedError)
#    [:greet] defined in AbstractParent
```
### Find unimplemented abstract methods
*abstractable#find_not_implemented_info* returns a following format Hash
```ruby
{abstract_class => array of unimplemented abstract methods, ...}
```
```ruby
class AbstractParent
  extend Abstractable
  abstract :greet
end

class Child < AbstractParent; end

Abstractable.find_not_implemented_info(Child) # => {AbstractParent=>[:greet]}
```
If call *find_not_implemented_info_from_singleton*,  
Then can find unimplemented abstract methods of singleton class.
```ruby
class AbstractParent
  class << self
    extend Abstractable
    abstract :greet
  end
end

class Child < AbstractParent; end

Abstractable.find_not_implemented_info_from_singleton(Child)
# => {#<Class:AbstractParent>=>[:greet]}
```
