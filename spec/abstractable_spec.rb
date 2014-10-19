require "spec_helper"

describe Abstractable, "Simple" do

  before(:context) do

    class AbstractList
      extend Abstractable
      abstract :size, :empty?, :add
    end

    class NotImplList < AbstractList; end

    class OneImplList < AbstractList
      def size; end
    end

    class AllImplList < OneImplList
      def empty?; end

      def add; end
    end

  end

  it "all implemented abstract methods" do
    expect { AllImplList.new }.not_to raise_error
    expect { AllImplList.allocate }.not_to raise_error
  end

  it "not implemented abstract methods" do
    expect do
      NotImplList.new
    end.to raise_error(NotImplementedError, <<-EOF.gsub(/^\s+|\n$/, ""))
      following abstract methods are not implemented.
      [:size, :empty?, :add] defined in AbstractList
    EOF
  end

  it "1 implemented abstract methods" do
    expect do
      OneImplList.new
    end.to raise_error(NotImplementedError, <<-EOF.gsub(/^\s+|\n$/, ""))
      following abstract methods are not implemented.
      [:empty?, :add] defined in AbstractList
    EOF
  end

  it "new abstract" do
    error_message = "#{AbstractList} has abstract methods. and therefore can't call new."
    expect do
      AbstractList.new
    end.to raise_error(Abstractable::WrongOperationError, error_message)
  end

  it "allocate abstract" do
    error_message = "#{AbstractList} has abstract methods. and therefore can't call allocate."
    expect do
      AbstractList.allocate
    end.to raise_error(Abstractable::WrongOperationError, error_message)
  end

end

describe Abstractable, "Complex class hierarchy" do

  before(:context) do

    module AbstractAddressHolder
      extend Abstractable
      abstract :city
      abstract :state, :zip
    end

    module AbstractNameHolder
      extend Abstractable
      abstract do
        def last_name; end

        def first_name; end
      end
    end

    class OneImplAddressHolder
      include AbstractAddressHolder
      def state; end
    end

    class TwoImplAdressAndNameHolder < OneImplAddressHolder
      include AbstractNameHolder
      def first_name; end
    end

    class AllImplAdressAndNameHolder
      include AbstractAddressHolder
      include AbstractNameHolder

      def last_name; end

      def first_name; end

      def city; end

      def state; end

      def zip; end
    end
  end

  it "all implemented abstract methods" do
    expect { AllImplAdressAndNameHolder.new }.not_to raise_error
  end

  it "1 implemented abstract methods" do
    expect do
      OneImplAddressHolder.new
    end.to raise_error(NotImplementedError, <<-EOF.gsub(/^\s+|\n$/, ""))
      following abstract methods are not implemented.
      [:city, :zip] defined in AbstractAddressHolder
    EOF
  end

  it "2 implemented abstract methods" do
    expect do
      TwoImplAdressAndNameHolder.new
    end.to raise_error(NotImplementedError, <<-EOF.gsub(/^\s+|\n$/, ""))
      following abstract methods are not implemented.
      [:city, :zip] defined in AbstractAddressHolder
      [:last_name] defined in AbstractNameHolder
    EOF
  end

end

describe Abstractable, "Independency" do

  before(:context) do
    class AbstractFormatter
      extend Abstractable
      abstract :format
    end

    class AFormatter < AbstractFormatter
      def format; end
    end

    class BFormatter < AbstractFormatter
      def format; end
    end

  end

  it "AFormatter & BFormatter validation is independent" do
    expect(AFormatter.required_validate?).to be_truthy
    expect(BFormatter.required_validate?).to be_truthy

    AFormatter.new
    expect(AFormatter.required_validate?).to be_falsey
    expect(BFormatter.required_validate?).to be_truthy

    BFormatter.new
    expect(AFormatter.required_validate?).to be_falsey
    expect(BFormatter.required_validate?).to be_falsey
  end

  it "Add later abstract method" do
    AbstractFormatter.abstract :close

    expect { AFormatter.new }.to raise_error(NotImplementedError)
    expect { BFormatter.new }.to raise_error(NotImplementedError)

    class AFormatter
      def close; end
    end
    expect { AFormatter.new }.not_to raise_error
    expect { BFormatter.new }.to raise_error(NotImplementedError)

    class BFormatter
      def close; end
    end
    expect { AFormatter.new }.not_to raise_error
    expect { BFormatter.new }.not_to raise_error
  end

end

describe Abstractable, "delete  abstract" do

  it "delete by undef_method & undef_abstract" do
    class AbstractWriter
      extend Abstractable
      abstract :write, :open, :close
    end

    class AbstractDocumentWriter < AbstractWriter
      abstract :write_document
    end

    class AbstractXMLDocumentWriter < AbstractDocumentWriter
      abstract :to_xml
    end

    class XMLDocumentWriter < AbstractXMLDocumentWriter; end

    expect { XMLDocumentWriter.new }.to raise_error(NotImplementedError)

    class AbstractXMLDocumentWriter
      undef_method :to_xml
    end

    expect(XMLDocumentWriter.abstract_methods).to eq([:write_document, :write, :open, :close])
    expect(AbstractXMLDocumentWriter.abstract_methods).to eq([:write_document, :write, :open, :close])
    expect(AbstractWriter.abstract_methods).to eq([:write, :open, :close])

    class AbstractDocumentWriter
      undef_method :write_document, :open, :close
    end

    expect(XMLDocumentWriter.abstract_methods).to eq([:write, :open, :close])
    expect(AbstractXMLDocumentWriter.abstract_methods).to eq([:write, :open, :close])
    expect(AbstractWriter.abstract_methods).to eq([:write, :open, :close])

    class AbstractWriter
      undef_method :write, :open, :close
    end

    expect(XMLDocumentWriter.abstract_methods).to eq([])
    expect(AbstractXMLDocumentWriter.abstract_methods).to eq([])
    expect(AbstractWriter.abstract_methods).to eq([])
  end

end

describe Abstractable, "Class method" do

  before(:context) do
    class AbstractApplication
      class << self
        extend Abstractable
        abstract :name
      end
    end

    class NotImplApplication < AbstractApplication; end

    class Application < AbstractApplication
      def self.name; end
    end

  end

  it "not implemented class method" do
    message = "name is abstract method defined in #{AbstractApplication.singleton_class}, and must implement."
    expect do
      NotImplApplication.name
    end.to raise_error(NotImplementedError, message)
  end

  it "implemented class method" do
    expect { Application.new }.not_to raise_error
  end

  it "find not implemented info from singleton class" do
    h = {AbstractApplication.singleton_class => [:name]}
    expect(Abstractable.find_not_implemented_info_from_singleton(NotImplApplication)).to eq(h)
    expect(Abstractable.find_not_implemented_info_from_singleton(Application)).to eq({})
  end

end

describe Abstractable, "Use environment variable: ABSTRACTABLE_IGNORE_VALIDATE" do

  before(:context) do
    class AbstractPerson
      extend Abstractable
      abstract :say
    end

    class NotImplPerson < AbstractPerson; end
  end

  it "if defined ABSTRACTABLE_IGNORE_VALIDATE then ignore validation." do
    expect(ENV).to receive(:[]).with("ABSTRACTABLE_IGNORE_VALIDATE").and_return(true)
    expect { NotImplPerson.new }.not_to raise_error
  end

end

describe Abstractable::NotImplementedInfoFinder do

  it "find" do
    class AbstractCollection
      extend Abstractable
      abstract :add, :remove
    end

    class AbstractQueue < AbstractCollection
      abstract :clear
    end

    class PriorityQueue < AbstractQueue; end

    abst_info1 = {AbstractCollection => [:add, :remove]}
    abst_info2 = {AbstractQueue => [:clear]}
    expect(Abstractable::NotImplementedInfoFinder.new.find(PriorityQueue)).to eq(abst_info1.merge(abst_info2))
    expect(Abstractable::NotImplementedInfoFinder.new.find(AbstractQueue)).to eq(abst_info1)
    expect(Abstractable::NotImplementedInfoFinder.new.find(AbstractCollection)).to eq({})
  end

end
