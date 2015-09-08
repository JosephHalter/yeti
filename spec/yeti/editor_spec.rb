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
      before{ allow(described_class).to receive(:new_object).with(context).and_return new_object }
      it "keeps given context" do
        expect(subject.context).to be context
      end
      it "#persist! is virtual" do
        expect do
          subject.persist!
        end.to raise_error NotImplementedError, "Yeti::Editor#persist!"
      end
      it "uses .new_object to initialize edited object" do
        expect(subject.edited).to eq(new_object)
      end
      it "delegates id to edited object" do
        is_expected.to delegates(:id).to :new_object
      end
      it "delegates to_param to edited object" do
        is_expected.to delegates(:to_param).to :new_object
      end
      it "delegates persisted? edited object" do
        is_expected.to delegates(:persisted?).to :new_object
      end
      it ".new_object can be nil" do
        allow(described_class).to receive :new_object
        expect(subject.edited).to be_nil
        expect(subject.id).to be_nil
        expect(subject.to_param).to be_nil
        expect(subject).not_to be_persisted
      end
    end
    context "initialize with context and object to edit" do
      subject{ described_class.new context, existing_object }
      it "keeps given context" do
        expect(subject.context).to be context
      end
      it "#persist! is virtual" do
        expect do
          subject.persist!
        end.to raise_error NotImplementedError, "Yeti::Editor#persist!"
      end
      it "delegates id to edited object" do
        is_expected.to delegates(:id).to :existing_object
      end
      it "delegates to_param to edited object" do
        is_expected.to delegates(:to_param).to :existing_object
      end
      it "delegates persisted? edited object" do
        is_expected.to delegates(:persisted?).to :existing_object
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
        expect(described_class).to receive(:new_object).with(context).and_return new_object
        expect(subject.edited).to be new_object
      end
    end
    context "when given_id is not nil" do
      let(:given_id){ "1" }
      it "uses .find_by_id to find object to edit" do
        expect(described_class).to receive(:find_by_id).with(context, "1") do
          existing_object
        end
        expect(subject.edited).to be existing_object
        expect(subject.id).to be 1
      end
    end
  end
  context "when not valid" do
    it "#save returns false" do
      expect(subject).to receive(:valid?).and_return false
      expect(subject).not_to receive :persist!
      expect(subject.save).to be false
    end
    it "#save(validate: false) calls persist! then returns true" do
      expect(subject).not_to receive :valid?
      expect(subject).to receive :persist!
      expect(subject.save(validate: false)).to be true
    end
  end
  context "when valid" do
    it "#save calls persist! then returns true" do
      expect(subject).to receive :persist!
      expect(subject.save).to be true
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
          Struct.new(:id, :name, :password).new nil, nil, nil
        end
      end
    end
    context "new record" do
      describe '#id' do
        subject { super().id }
        it { is_expected.to be_nil }
      end

      describe '#name' do
        subject { super().name }
        it { is_expected.to be_nil }
      end
      it "#name= don't touch value if it's not a string" do
        subject.name = ["test"]
        expect(subject.name).to eq(["test"])
      end
      it "#name= cleans the value of harmful content if it's a string" do
        subject.name = "\tInfected\210\004"
        expect(subject.name).to eq("Infected")
      end
      it "#name= accepts nil" do
        subject.name = "Valid"
        subject.name = nil
        expect(subject.name).to be_nil
      end
      it "#attributes returns a hash" do
        expect(subject.attributes).to eq({name: nil})
      end
      it "#attributes= assigns each attribute" do
        expect(subject).to receive(:name=).with "Anthony"
        subject.attributes = {name: "Anthony"}
      end
      it "#attributes= skips unknown attributes" do
        subject.attributes = {unknown: "Anthony"}
        expect(subject.attributes).to eq({name: nil})
      end
      context "before validation" do
        describe '#errors' do
          subject { super().errors }
          it { is_expected.to be_empty }
        end
        it{ is_expected.to be_without_error }
      end
      context "after validation" do
        it "has an error on name" do
          subject.valid?
          expect(subject.errors[:name].size).to eq(1)
          expect(subject.errors[:name]).to eq(["can't be blank"])
        end
        it "is not without_error? anymore" do
          subject.valid?
          expect(subject).not_to be_without_error
        end
        it "can return untranslated error messages" do
          described_class.class_eval do
            dont_translate_error_messages
          end
          subject.valid?
          expect(subject.errors[:name]).to eq([:blank])
        end
        it "message can be overridden" do
          described_class.class_eval do
            attribute :password
            validates_presence_of :password, message: "overridden message"
          end
          subject.valid?
          expect(subject.errors[:password]).to eq(["overridden message"])
        end
      end
      context "when name is empty" do
        it{ is_expected.not_to be_valid }
      end
      context "when name is changed" do
        before{ subject.name = "Anthony" }
        it{ is_expected.to be_valid }
        it "#attributes is updated" do
          expect(subject.attributes).to eq({name: "Anthony"})
        end
        it("name is updated"){ expect(subject.name).to eq("Anthony") }
        it("name is dirty"){ expect(subject.name_changed?).to be true }
        it "name isn't dirty anymore if original value is set back" do
          subject.name = nil
          expect(subject.name_changed?).to be false
        end
      end
      context "after save" do
        before do
          subject.name = "Anthony"
          allow(subject).to receive :persist!
          subject.save
        end
        it "resets dirty attributes" do
          expect(subject.name_changed?).to be false
        end
        it "still knows previous changes" do
          expect(subject.previous_changes).to eq({"name"=>[nil, "Anthony"]})
        end
      end
    end
    context "existing record" do
      let(:existing_object){ double :existing_object, id: 1, name: "Anthony" }
      subject{ described_class.new context, existing_object }
      it("gets id from record"){ expect(subject.id).to be 1 }
      it "gets name from record" do
        expect(subject.name).to eq("Anthony")
      end
      it{ is_expected.to be_valid }
      it "output formatting can be customized" do
        allow(subject).to receive(:format_output).with("Anthony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = double)
        expect(subject.name).to be expected
      end
      it "input formatting can be customized" do
        allow(subject).to receive(:format_input).with("Tony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = double)
        subject.name = "Tony"
        expect(subject.name).to be expected
      end
      context "when name is changed" do
        before{ subject.name = nil }
        it("name is updated"){ expect(subject.name).to be_nil }
        it("name is dirty"){ expect(subject.name_changed?).to be true }
        it "name isn't dirty anymore if original value is set back" do
          subject.name = "Anthony"
          expect(subject.name_changed?).to be false
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
      expect(subject.id).to eq(1)
      expect(subject.name).to eq("Anthony")
    end
    it "attribute value can come from another object" do
      expect(subject.description).to eq("Business man")
    end
    it "attribute value can come from nowhere" do
      expect(subject.password).to be_nil
    end
    it "attribute value can come from specified method on self" do
      expect(subject.timestamp).to eq("2001-01-01")
    end
    it "attribute value can come from specified method on another object" do
      expect(subject.related_id).to eq(2)
    end
    it "attribute raises if value cannot be found in source" do
      expect{ subject.invalid }.to raise_error NoMethodError
    end
    it "calling an undefined method doesn't trigger a stack overflow" do
      expect{ subject.undefined }.to raise_error NoMethodError
    end
    it "do not assign default value on access" do
      expect(subject.with_default_from_another_attribute).to eq(2)
      expect(subject.instance_variable_get(:@with_default_from_another_attribute)).to be_nil
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
      expect(subject.mandatory?(:name)).to be true
    end
    it "is false for an attribute without validates_presence_of" do
      expect(subject.mandatory?(:password)).to be false
    end
    it "is false for an invalid attribute" do
      expect(subject.mandatory?(:invalid)).to be false
    end
  end
  describe "equality" do
    let(:existing){ double :object, id: 1, persisted?: true }
    let(:another){ double :object, id: 2, persisted?: true }
    subject{ described_class.from_id context, 1 }
    before do
      allow(described_class).to receive(:find_by_id).with(context, 1).and_return existing
      allow(described_class).to receive(:find_by_id).with(context, 2).and_return another
      allow(described_class).to receive(:new_object).with(context) do
        double persisted?: false, id: nil
      end
    end
    it "two new editors are not equal" do
      subject = described_class.new context
      other = described_class.new context
      expect(subject).not_to eq(other)
      expect(subject).not_to eql other
      expect(subject.hash).to eq(other.hash)
    end
    it "two editors of the same class with the same id are equal" do
      other = described_class.from_id context, 1
      expect(subject).to eq(other)
      expect(subject).to eql other
      expect(subject.hash).to eq(other.hash)
    end
    it "two editors of the same class with different ids are not equal" do
      other = described_class.from_id context, 2
      expect(subject).not_to eq(other)
      expect(subject).not_to eql other
      expect(subject.hash).not_to eq(other.hash)
    end
    it "two editors of different classes with the same id are not equal" do
      other = Class.new(described_class).from_id context, 1
      expect(subject).not_to eq(other)
      expect(subject).not_to eql other
      expect(subject.hash).to eq(other.hash)
    end
  end
  describe "#attributes_for_persist" do
    subject{ described_class.new context }
    before{ allow(described_class).to receive(:new_object).with(context).and_return record }
    context "parses date format" do
      let :described_class do
        Class.new ::Yeti::Editor do
          attribute :valid_from, as: :date
        end
      end
      let(:record){ double :new_record, valid_from: Date.parse("2002-09-01") }
      it "when a new value is assigned" do
        subject.valid_from = "2002-12-31"
        expect(subject.attributes).to eq({valid_from: "2002-12-31"})
        expect(subject.attributes_for_persist).to eq({
          valid_from: Date.parse("2002-12-31")
        })
      end
      it "without new value" do
        expect(subject.attributes).to eq({valid_from: Date.parse("2002-09-01")})
        expect(subject.attributes_for_persist).to eq({
          valid_from: Date.parse("2002-09-01")
        })
      end
      it "when nil is assigned" do
        subject.valid_from = nil
        expect(subject.attributes).to eq({valid_from: nil})
        expect(subject.attributes_for_persist).to eq({valid_from: nil})
      end
      it "when date is assigned" do
        today = Date.today
        subject.valid_from = today
        expect(subject.attributes).to eq({valid_from: today})
        expect(subject.attributes_for_persist).to eq({valid_from: today})
      end
      it "when incorrect value is assigned" do
        subject.valid_from = "2002-13-31"
        expect(subject.attributes).to eq({valid_from: "2002-13-31"})
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
        expect(subject).to receive(:format_input_for_persist).with(
          "Tony",
          attribute_name: :name,
          from: :edited
        ).and_return "Anthony"
        expect(subject.attributes_for_persist).to eq({name: "Anthony"})
      end
    end
  end
  describe "allows defining additional attributes in subclass" do
    subject{ described_class.new context }
    before{ allow(described_class).to receive(:new_object).with(context).and_return record }
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
      expect(subject.attributes).to eq({
        name: "Anthony",
        password: "tony",
      })
    end
  end
  context "#update_attributes" do
    it "can be called without argument" do
      expect(subject).to receive(:attributes=).with({})
      expect(subject).to receive(:save).and_return(expected = double)
      expect( subject.update_attributes ).to be expected
    end
    it "can be called with attributes" do
      expect(subject).to receive(:attributes=).with name: "Anthony"
      expect(subject).to receive(:save).and_return(expected = double)
      expect( subject.update_attributes name: "Anthony" ).to be expected
    end
  end
  describe "allows attribute to be called value" do
    let :described_class do
      Class.new ::Yeti::Editor do
        attribute :value
      end
    end
    subject{ described_class.new context }
    let(:record){ double :new_record, value: nil }
    before{ allow(described_class).to receive(:new_object).with(context).and_return record }
    it "can assign a new value" do
      subject.value = "test"
      expect(subject.value).to eq "test"
    end
  end
end
