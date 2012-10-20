require "spec_helper"

describe Yeti::Context do
  context "initialization" do
    it "requires a hash with account_id" do
      lambda{ Yeti::Context.new }.should raise_error ArgumentError, "wrong number of arguments (0 for 1)"
      lambda{ Yeti::Context.new key: nil }.should raise_error KeyError, "key not found: :account_id"
    end
  end
  context "when account_id is nil" do
    subject{ Yeti::Context.new account_id: nil }
    it "#account is an instance of Yeti::Context::NoAccount" do
      subject.account.should be_kind_of Yeti::Context::NoAccount
    end
    it("#account_id is nil"){ subject.account_id.should be_nil }
    it "no account can be overriden by subclasses" do
      subclass = Class.new Yeti::Context do
        def no_account
          :custom_no_account
        end
      end
      subject = subclass.new account_id: nil
      subject.account.should == :custom_no_account
    end
  end
  context "when account_id" do
    subject{ Yeti::Context.new account_id: 1 }
    it "uses find_account_by_id to find account" do
      subject.stub(:find_account_by_id).with(1).and_return(expected = mock)
      subject.account.should be expected
    end
    it "#find_account_by_id is virtual" do
      lambda do
        subject.find_account_by_id 1
      end.should raise_error NotImplementedError
    end
    it "#account_id returns account.id" do
      subject.stub(:find_account_by_id).with(1).and_return mock(id: 2)
      subject.account_id.should be 2
    end
  end
end
