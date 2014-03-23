require "spec_helper"

describe ::Yeti::Editor do
  let(:context){ double :context }
  subject{ described_class.new context }
  it ".new_object is virtual" do
    expect do
      described_class.new_object context
    end.to raise_error NotImplementedError, "Yeti::Editor.new_object"
  end
  it ".find_by_id is virtual" do
    expect do
      described_class.find_by_id context, 1
    end.to raise_error NotImplementedError, "Yeti::Editor.find_by_id"
  end
  describe "initialization" do
    let(:new_object){ double :new_object }
    let(:existing_object){ double :existing_object }
    context "with context only" do
      before{ described_class.stub(:new_object).with(context).and_return new_object }
      it "keeps given context" do
        subject.context.should be context
      end
      it "#persist! is virtual" do
        expect do
          subject.persist!
        end.to raise_error NotImplementedError, "Yeti::Editor#persist!"
      end
      it "uses .new_object to initialize edited object" do
        subject.edited.should == new_object
      end
      it "delegates id to edited object" do
        should delegates(:id).to :new_object
      end
      it "delegates to_param to edited object" do
        should delegates(:to_param).to :new_object
      end
      it "delegates persisted? edited object" do
        should delegates(:persisted?).to :new_object
      end
      it ".new_object can be nil" do
        described_class.stub :new_object
        subject.edited.should be_nil
        subject.id.should be_nil
        subject.to_param.should be_nil
        subject.should_not be_persisted
      end
    end
    context "initialize with context and object to edit" do
      subject{ described_class.new context, existing_object }
      it "keeps given context" do
        subject.context.should be context
      end
      it "#persist! is virtual" do
        expect do
          subject.persist!
        end.to raise_error NotImplementedError, "Yeti::Editor#persist!"
      end
      it "delegates id to edited object" do
        should delegates(:id).to :existing_object
      end
      it "delegates to_param to edited object" do
        should delegates(:to_param).to :existing_object
      end
      it "delegates persisted? edited object" do
        should delegates(:persisted?).to :existing_object
      end
    end
  end
  describe ".from_id(context, given_id)" do
    let(:new_object){ double :new_object }
    let(:existing_object){ double :existing_object, id: 1 }
    subject{ described_class.from_id context, given_id }
    context "when given_id is nil" do
      let(:given_id){ nil }
      it "uses .new_object to generate object to edit" do
        described_class.should_receive(:new_object).with(context).and_return new_object
        subject.edited.should be new_object
      end
    end
    context "when given_id is not nil" do
      let(:given_id){ "1" }
      it "uses .find_by_id to find object to edit" do
        described_class.should_receive(:find_by_id).with(context, "1").and_return do
          existing_object
        end
        subject.edited.should be existing_object
        subject.id.should be 1
      end
    end
  end
  context "when not valid" do
    it "#save returns false" do
      subject.should_receive(:valid?).and_return false
      subject.should_not_receive :persist!
      subject.save.should be false
    end
    it "#save(validate: false) calls persist! then returns true" do
      subject.should_not_receive :valid?
      subject.should_receive :persist!
      subject.save(validate: false).should be true
    end
  end
  context "when valid" do
    it "#save calls persist! then returns true" do
      subject.should_receive :persist!
      subject.save.should be true
    end
  end
  context "editor of one record" do
    let :described_class do
      Class.new ::Yeti::Editor do
        attribute :name
        validates_presence_of :name
        def self.name
          "ObjectEditor"
        end
        def self.new_object(context)
          Struct.new(:id, :name).new nil, nil
        end
      end
    end
    context "new record" do
      its(:id){ should be_nil }
      its(:name){ should be_nil }
      it "#name= don't touch value if it's not a string" do
        subject.name = ["test"]
        subject.name.should == ["test"]
      end
      it "#name= cleans the value of harmful content if it's a string" do
        subject.name = "\tInfected\210\004"
        subject.name.should == "Infected"
      end
      it "#name= accepts nil" do
        subject.name = "Valid"
        subject.name = nil
        subject.name.should be_nil
      end
      it "#attributes returns a hash" do
        subject.attributes.should == {name: nil}
      end
      it "#attributes= assigns each attribute" do
        subject.should_receive(:name=).with "Anthony"
        subject.attributes = {name: "Anthony"}
      end
      it "#attributes= skips unknown attributes" do
        subject.attributes = {unknown: "Anthony"}
      end
      context "before validation" do
        its(:errors){ should be_empty }
        it{ should be_without_error }
      end
      context "after validation" do
        it "has an error on name" do
          subject.valid?
          subject.errors[:name].should have(1).item
          subject.errors[:name].should == ["can't be blank"]
        end
        it "is not without_error? anymore" do
          subject.valid?
          subject.should_not be_without_error
        end
        it "can return untranslated error messages" do
          described_class.class_eval do
            dont_translate_error_messages
          end
          subject.valid?
          subject.errors[:name].should == [:blank]
        end
      end
      context "when name is empty" do
        it{ should_not be_valid }
      end
      context "when name is changed" do
        before{ subject.name = "Anthony" }
        it{ should be_valid }
        it "#attributes is updated" do
          subject.attributes.should == {name: "Anthony"}
        end
        it("name is updated"){ subject.name.should == "Anthony" }
        it("name is dirty"){ subject.name_changed?.should be true }
        it "name isn't dirty anymore if original value is set back" do
          subject.name = nil
          subject.name_changed?.should be false
        end
      end
      context "after save" do
        before do
          subject.name = "Anthony"
          subject.stub :persist!
          subject.save
        end
        it "resets dirty attributes" do
          subject.name_changed?.should be false
        end
        it "still knows previous changes" do
          subject.previous_changes.should == {"name"=>[nil, "Anthony"]}
        end
      end
    end
    context "existing record" do
      let(:existing_object){ double :existing_object, id: 1, name: "Anthony" }
      subject{ described_class.new context, existing_object }
      it("gets id from record"){ subject.id.should be 1 }
      it "gets name from record" do
        subject.name.should == "Anthony"
      end
      it{ should be_valid }
      it "output formatting can be customized" do
        subject.stub(:format_output).with("Anthony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = double)
        subject.name.should be expected
      end
      it "input formatting can be customized" do
        subject.stub(:format_input).with("Tony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = double)
        subject.name = "Tony"
        subject.name.should be expected
      end
      context "when name is changed" do
        before{ subject.name = nil }
        it("name is updated"){ subject.name.should be_nil }
        it("name is dirty"){ subject.name_changed?.should be true }
        it "name isn't dirty anymore if original value is set back" do
          subject.name = "Anthony"
          subject.name_changed?.should be false
        end
      end
    end
  end
  context "editor of multiple records" do
    let(:existing_object){ Struct.new(:id, :name).new 1, "Anthony" }
    subject do
      Class.new described_class do
        attribute :name
        attribute :description, from: :related
        attribute :password, from: nil
        attribute :timestamp, from: ".timestamp_str"
        attribute :related_id, from: "related.id"
        attribute :invalid
        attribute :with_default_from_another_attribute, from: ".related_id"

        def related
          Struct.new(:id, :description).new 2, "Business man"
        end

      private

        def timestamp_str
          "2001-01-01"
        end

      end.new context, existing_object
    end
    it "attribute default value comes from edited" do
      subject.id.should == 1
      subject.name.should == "Anthony"
    end
    it "attribute value can come from another object" do
      subject.description.should == "Business man"
    end
    it "attribute value can come from nowhere" do
      subject.password.should be_nil
    end
    it "attribute value can come from specified method on self" do
      subject.timestamp.should == "2001-01-01"
    end
    it "attribute value can come from specified method on another object" do
      subject.related_id.should == 2
    end
    it "attribute raises if value cannot be found in source" do
      expect{ subject.invalid }.to raise_error NoMethodError
    end
    it "do not assign default value on access" do
      subject.with_default_from_another_attribute.should eq(2)
      subject.instance_variable_get(:@with_default_from_another_attribute).should be_nil
    end
  end
  describe "#mandatory?" do
    subject do
      Class.new described_class do
        validates_presence_of :name
        attribute :name
        attribute :password
      end.new context
    end
    it "is true for an attribute with validates_presence_of" do
      subject.mandatory?(:name).should be true
    end
    it "is false for an attribute without validates_presence_of" do
      subject.mandatory?(:password).should be false
    end
    it "is false for an invalid attribute" do
      subject.mandatory?(:invalid).should be false
    end
  end
  describe "equality" do
    let(:existing){ double :object, id: 1, persisted?: true }
    let(:another){ double :object, id: 2, persisted?: true }
    subject{ described_class.from_id context, 1 }
    before do
      described_class.stub(:find_by_id).with(context, 1).and_return existing
      described_class.stub(:find_by_id).with(context, 2).and_return another
      described_class.stub(:new_object).with(context).and_return do
        double persisted?: false, id: nil
      end
    end
    it "two new editors are not equal" do
      subject = described_class.new context
      other = described_class.new context
      subject.should_not == other
      subject.should_not eql other
      subject.hash.should == other.hash
    end
    it "two editors of the same class with the same id are equal" do
      other = described_class.from_id context, 1
      subject.should == other
      subject.should eql other
      subject.hash.should == other.hash
    end
    it "two editors of the same class with different ids are not equal" do
      other = described_class.from_id context, 2
      subject.should_not == other
      subject.should_not eql other
      subject.hash.should_not == other.hash
    end
    it "two editors of different classes with the same id are not equal" do
      other = Class.new(described_class).from_id context, 1
      subject.should_not == other
      subject.should_not eql other
      subject.hash.should == other.hash
    end
  end
  describe "#attributes_for_persist" do
    subject{ described_class.new context }
    before{ described_class.stub(:new_object).with(context).and_return record }
    context "parses date format" do
      let :described_class do
        Class.new ::Yeti::Editor do
          attribute :valid_from, as: :date
        end
      end
      let(:record){ double :new_record, valid_from: Date.parse("2002-09-01") }
      it "when a new value is assigned" do
        subject.valid_from = "2002-12-31"
        subject.attributes.should == {valid_from: "2002-12-31"}
        subject.attributes_for_persist.should == {
          valid_from: Date.parse("2002-12-31")
        }
      end
      it "without new value" do
        subject.attributes.should == {valid_from: Date.parse("2002-09-01")}
        subject.attributes_for_persist.should == {
          valid_from: Date.parse("2002-09-01")
        }
      end
      it "when nil is assigned" do
        subject.valid_from = nil
        subject.attributes.should == {valid_from: nil}
        subject.attributes_for_persist.should == {valid_from: nil}
      end
      it "when date is assigned" do
        today = Date.today
        subject.valid_from = today
        subject.attributes.should == {valid_from: today}
        subject.attributes_for_persist.should == {valid_from: today}
      end
      it "when incorrect value is assigned" do
        subject.valid_from = "2002-13-31"
        subject.attributes.should == {valid_from: "2002-13-31"}
        expect do
          subject.attributes_for_persist
        end.to raise_error ::Yeti::Editor::InvalidDate, "2002-13-31"
      end
    end
    context "formatting can be changed with #format_input_for_persist" do
      let :described_class do
        Class.new ::Yeti::Editor do
          attribute :name
        end
      end
      let(:record){ double :new_record, name: nil }
      it "uses format_input_for_persist on each value" do
        subject.name = "Tony"
        subject.should_receive(:format_input_for_persist).with(
          "Tony",
          attribute_name: :name,
          from: :edited
        ).and_return "Anthony"
        subject.attributes_for_persist.should == {name: "Anthony"}
      end
    end
  end
  describe "allows defining additional attributes in subclass" do
    subject{ described_class.new context }
    before{ described_class.stub(:new_object).with(context).and_return record }
    let(:record){ double :new_record, name: "Anthony", password: "tony" }
    let :parent_class do
      Class.new ::Yeti::Editor do
        attribute :name
      end
    end
    let :described_class do
      Class.new parent_class do
        attribute :password
      end
    end
    it "merges attributes from parent" do
      subject.attributes.should == {
        name: "Anthony",
        password: "tony",
      }
    end
  end
end
