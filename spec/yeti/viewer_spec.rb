require "spec_helper"

describe ::Yeti::Viewer do
  let(:context){ mock :context }
  subject{ described_class.new context }
  it ".find_by_id is virtual" do
    lambda do
      described_class.find_by_id context, 1
    end.should raise_error NotImplementedError, "Yeti::Viewer.find_by_id"
  end
  describe "initialization" do
    let(:existing_object){ mock :existing_object }
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
    let(:existing_object){ mock :existing_object }
    subject{ described_class.from_id context, "1" }
    it "uses .find_by_id to find object to edit" do
      described_class.should_receive(:find_by_id).with(context, "1").and_return do
        existing_object
      end
      subject.decorated.should be existing_object
    end
  end
end
