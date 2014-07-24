require "spec_helper"

describe Yeti::Context do
  context "without hash" do
    it "#account is an instance of Yeti::Context::NoAccount" do
      expect(Yeti::Context.new.account).to be_kind_of Yeti::Context::NoAccount
    end
  end
  context "when account_id is not in hash" do
    it "#account is an instance of Yeti::Context::NoAccount" do
      expect(Yeti::Context.new({}).account).to be_kind_of Yeti::Context::NoAccount
    end
  end
  context "when account_id is nil" do
    subject{ Yeti::Context.new account_id: nil }
    it "#account is an instance of Yeti::Context::NoAccount" do
      expect(subject.account).to be_kind_of Yeti::Context::NoAccount
    end
    it("#account_id is nil"){ expect(subject.account_id).to be_nil }
    it "no account can be overriden by subclasses" do
      subclass = Class.new Yeti::Context do
        def no_account
          :custom_no_account
        end
      end
      subject = subclass.new account_id: nil
      expect(subject.account).to eq(:custom_no_account)
    end
  end
  context "when account_id" do
    subject{ Yeti::Context.new account_id: 1 }
    it "uses find_account_by_id to find account" do
      allow(subject).to receive(:find_account_by_id).with(1).and_return(expected = double)
      expect(subject.account).to be expected
    end
    it "#find_account_by_id is virtual" do
      expect do
        subject.find_account_by_id 1
      end.to raise_error NotImplementedError
    end
    it "#account_id returns account.id" do
      allow(subject).to receive(:find_account_by_id).with(1).and_return double(id: 2)
      expect(subject.account_id).to be 2
    end
  end
end
