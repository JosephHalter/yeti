require "spec_helper"

describe Yeti::Editor do
  let(:context){ mock :context }
  subject{ Yeti::Editor.new context, nil }
  it "should keep given context" do
    subject.context.should be context
  end
  it "#find_by_id should be virtual" do
    lambda{ subject.find_by_id 1 }.should raise_error NotImplementedError
  end
  it "#new_object should be virtual" do
    lambda{ subject.new_object }.should raise_error NotImplementedError
  end
  it "#persist! should be virtual" do
    lambda{ subject.persist! }.should raise_error NotImplementedError
  end
  context "with a given id" do
    subject{ Yeti::Editor.new context, 1 }
    it{ should be_persisted }
    it "#edited should use #find_by_id" do
      subject.stub(:find_by_id).with(1).and_return(expected = mock)
      subject.edited.should be expected
    end
  end
  context "without id" do
    it{ should_not be_persisted }
    it "#edited should use #new_object" do
      subject.stub(:new_object).and_return(expected = mock)
      subject.edited.should be expected
    end
  end
  context "when not valid" do
    before{ subject.stub(:valid?).and_return false }
    it "#save should return false" do
      subject.save.should be false
    end
  end
  context "when valid" do
    it "#save should call persist! then return true" do
      subject.should_receive :persist!
      subject.save.should be true
    end
  end
  context "editor of one record" do
    let :object_editor do
      Class.new Yeti::Editor do
        attribute :name
        validates_presence_of :name
        def self.name
          "ObjectEditor"
        end
      end
    end
    context "new record" do
      subject{ object_editor.new context, nil }
      let(:new_record){ mock :new_record, name: nil, id: nil }
      before{ subject.stub(:new_object).and_return new_record }
      its(:id){ should be_nil }
      its(:name){ should be_nil }
      it "#name= should convert input to string" do
        subject.name = ["test"]
        subject.name.should == "[\"test\"]"
      end
      it "#name= should clean the value" do
        subject.name = "\tInfected\210\004"
        subject.name.should == "Infected"
      end
      it "#name= should accept nil" do
        subject.name = "Valid"
        subject.name = nil
        subject.name.should be_nil
      end
      it "#attributes should return a hash" do
        subject.attributes.should == {name: nil}
      end
      it "#attributes= should assign each attribute" do
        subject.should_receive(:name=).with "Anthony"
        subject.attributes = {name: "Anthony"}
      end
      it "#attributes= should skip unknown attributes" do
        subject.attributes = {unknown: "Anthony"}
      end
      context "before validation" do
        its(:errors){ should be_empty }
      end
      context "after validation" do
        it "should have an error on name" do
          subject.valid?
          subject.errors[:name].should have(1).item
          subject.errors[:name].should == ["can't be blank"]
        end
        it "should be able to return untranslated error messages" do
          object_editor.class_eval do
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
        it "#attributes should be updated" do
          subject.attributes.should == {name: "Anthony"}
        end
        it("name should be updated"){ subject.name.should == "Anthony" }
        it("name should be dirty"){ subject.name_changed?.should be true }
        it "name should not be dirty anymore if original value is reset" do
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
        it "should reset dirty attributes" do
          subject.name_changed?.should be false
        end
        it "should still know previous changes" do
          subject.previous_changes.should == {"name"=>[nil, "Anthony"]}
        end
      end
    end
    context "existing record" do
      subject{ object_editor.new context, 1 }
      let(:existing_record){ mock :existing_record, name: "Anthony", id: 1 }
      before{ subject.stub(:find_by_id).with(1).and_return existing_record }
      it("should get id from record"){ subject.id.should be 1 }
      it "should get name from record" do
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
        it("name should be updated"){ subject.name.should be_nil }
        it("name should be dirty"){ subject.name_changed?.should be true }
        it "name should not be dirty anymore if original value is reset" do
          subject.name = "Anthony"
          subject.name_changed?.should be false
        end
      end
    end
  end
  context "editor of multiple records" do
    let :object_editor do
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
    subject{ object_editor.new context, 1 }
    it "attribute default value come from edited" do
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
