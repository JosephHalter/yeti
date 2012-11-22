require "spec_helper"

describe Yeti::Editor do
  let(:context){ mock :context }
  subject{ Yeti::Editor.new context }
  it "keeps given context" do
    subject.context.should be context
  end
  it "#find_by_id is virtual" do
    lambda{ subject.find_by_id 1 }.should raise_error NotImplementedError
  end
  it "#new_object is virtual" do
    lambda{ subject.new_object }.should raise_error NotImplementedError
  end
  it "#persist! is virtual" do
    lambda{ subject.persist! }.should raise_error NotImplementedError
  end
  context "with a given id" do
    subject{ Yeti::Editor.new context, 1 }
    it{ should be_persisted }
    it "uses #find_by_id to find the main object being edited" do
      subject.stub(:find_by_id).with(1).and_return(expected = mock)
      subject.edited.should be expected
    end
  end
  context "with id nil" do
    subject{ Yeti::Editor.new context, nil }
    it{ should_not be_persisted }
    it "uses #new_object to initialize main object being edited" do
      subject.stub(:new_object).and_return(expected = mock)
      subject.edited.should be expected
    end
  end
  context "without id" do
    it{ should_not be_persisted }
    it "uses #new_object to initialize main object being edited" do
      subject.stub(:new_object).and_return(expected = mock)
      subject.edited.should be expected
    end
  end
  context "when not valid" do
    before{ subject.stub(:valid?).and_return false }
    it "#save returns false" do
      subject.save.should be false
    end
    it "#save(validate: false) calls persist! then returns true" do
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
    let :editor_class do
      Class.new Yeti::Editor do
        attribute :name
        validates_presence_of :name
        def self.name
          "ObjectEditor"
        end
      end
    end
    context "new record" do
      subject{ editor_class.new context, nil }
      let(:new_record){ mock :new_record, name: nil, id: nil }
      before{ subject.stub(:new_object).and_return new_record }
      its(:id){ should be_nil }
      its(:name){ should be_nil }
      it "#name= converts input to string" do
        subject.name = ["test"]
        subject.name.should == "[\"test\"]"
      end
      it "#name= cleans the value of any harmful content" do
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
          editor_class.class_eval do
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
      subject{ editor_class.new context, 1 }
      let(:existing_record){ mock :existing_record, name: "Anthony", id: 1 }
      before{ subject.stub(:find_by_id).with(1).and_return existing_record }
      it("gets id from record"){ subject.id.should be 1 }
      it "gets name from record" do
        subject.name.should == "Anthony"
      end
      it{ should be_valid }
      it "input formatting can be customized" do
        subject.stub(:format_input).with("Anthony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = mock)
        subject.name.should be expected
      end
      it "output formatting can be customized" do
        subject.stub(:format_output).with("Tony", {
          attribute_name: :name,
          from: :edited,
        }).and_return(expected = mock)
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
    let :editor_class do
      Class.new Yeti::Editor do
        attribute :name
        attribute :description, from: :related
        attribute :password, from: nil
        attribute :timestamp, from: ".timestamp_str"
        attribute :related_id, from: "related.id"
        attribute :invalid
        def find_by_id(id)
          Struct.new(:id, :name).new(id, "Anthony")
        end
        def related
          Struct.new(:id, :description).new 2, "Business man"
        end
        def timestamp_str
          "2001-01-01"
        end
      end
    end
    subject{ editor_class.new context, 1 }
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
      subject.related_id.should == "2"
    end
    it "attribute raises if value cannot be found in source" do
      lambda{ subject.invalid }.should raise_error NoMethodError
    end
  end
end
