require "spec_helper"

describe ::Yeti::Viewer do
  let(:context){ double :context }
  it ".find_by_id is virtual" do
    expect do
      described_class.find_by_id context, 1
    end.to raise_error NotImplementedError, "Yeti::Viewer.find_by_id"
  end
  describe "initialization" do
    let(:existing_object){ double :existing_object }
    subject{ described_class.new context, existing_object }
    it "keeps given context" do
      subject.context.should be context
    end
    it "keeps given object to decorate" do
      subject.decorated.should be existing_object
    end
    it "delegates id to decorated object" do
      should delegates(:id).to :existing_object
    end
    it "delegates to_param to decorated object" do
      should delegates(:to_param).to :existing_object
    end
    it "delegates persisted? decorated object" do
      should delegates(:persisted?).to :existing_object
    end
  end
  describe ".from_id(context, given_id)" do
    let(:existing_object){ double :existing_object }
    subject{ described_class.from_id context, "1" }
    it "uses .find_by_id to find object to edit" do
      described_class.should_receive(:find_by_id).with(context, "1").and_return do
        existing_object
      end
      subject.decorated.should be existing_object
    end
  end
  describe "equality" do
    let(:existing){ double :object, id: 1 }
    let(:another){ double :object, id: 2 }
    subject{ described_class.from_id context, 1 }
    before do
      described_class.stub(:find_by_id).with(context, 1).and_return existing
      described_class.stub(:find_by_id).with(context, 2).and_return another
    end
    it "two viewers of the same class with the same id are equal" do
      other = described_class.from_id context, 1
      subject.should == other
      subject.should eql other
      subject.hash.should == other.hash
    end
    it "two viewers of the same class with different ids are not equal" do
      other = described_class.from_id context, 2
      subject.should_not == other
      subject.should_not eql other
      subject.hash.should_not == other.hash
    end
    it "two viewers of different classes with the same id are not equal" do
      other = Class.new(described_class).from_id context, 1
      subject.should_not == other
      subject.should_not eql other
      subject.hash.should == other.hash
    end
  end
end
