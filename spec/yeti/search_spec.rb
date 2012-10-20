require "spec_helper"

describe Yeti::Search do
  let(:context){ mock :context }
  context "initialization" do
    it "does require a context and a hash" do
      message = "wrong number of arguments (1 for 2)"
      lambda do
        Yeti::Search.new context
      end.should raise_error ArgumentError, message
    end
  end
  context "given context and an empty hash" do
    subject{ Yeti::Search.new context, {} }
    it "keeps given context" do
      subject.context.should be context
    end
    it "#search defaults to {}" do
      subject.search.should == {}
    end
    it "#page defaults to 1" do
      subject.page.should == 1
    end
    it "#per_page defaults to 20" do
      subject.per_page.should == 20
    end
  end
  context "given context and params" do
    let :search do
      {
        "name_contains" => "tony",
        "popular_equals" => "1",
        "created_at_gte" => "2001-01-01",
        "created_at_lte" => "2002-01-01",
        "uncommon_filter" => "1",
      }
    end
    let(:results){ mock :results }
    subject{ Yeti::Search.new context, search: search }
    before{ subject.stub(:results).and_return results }
    it "#search comes from hash" do
      subject.search.should == search
    end
    it "gets common filters from search" do
      subject.should respond_to(:name_contains)
      subject.should respond_to(:popular_equals)
      subject.should respond_to(:created_at_gte)
      subject.should respond_to(:created_at_lte)
      subject.name_contains.should == "tony"
      subject.popular_equals.should == "1"
      subject.created_at_gte.should == "2001-01-01"
      subject.created_at_lte.should == "2002-01-01"
    end
    it "doesn't get everything from search" do
      subject.should_not respond_to(:uncommon_filter)
      lambda{ subject.invalid_method }.should raise_error NoMethodError
      lambda{ subject.uncommon_filter }.should raise_error NoMethodError
    end
    it "#page comes from hash" do
      Yeti::Search.new(context, page: "2").page.should be 2
    end
    it "doesn't accept page to be lower than 1" do
      Yeti::Search.new(context, page: "0").page.should be 1
    end
    it "#per_page comes from hash" do
      Yeti::Search.new(context, per_page: "10").per_page.should be 10
    end
    it "doesn't accept per_page to be lower than 1" do
      Yeti::Search.new(context, per_page: "0").per_page.should be 1
    end
    it "by default per_page has no limit" do
      Yeti::Search.max_per_page.should be_nil
      Yeti::Search.new(context, per_page: "9999").per_page.should be 9999
    end
    it "per_page can be limited" do
      search_class = Class.new Yeti::Search do
        max_per_page 50
      end
      search_class.max_per_page.should be 50
      search_class.new(context, per_page: "9999").per_page.should be 50
    end
    it "#paginated_results is virtual" do
      lambda do
        subject.paginated_results
      end.should raise_error NotImplementedError
    end
    it{ should delegates(:to_ary).to :results }
    it{ should delegates(:empty?).to :results }
    it{ should delegates(:each).to :results }
    it{ should delegates(:group_by).to :results }
    it{ should delegates(:size).to :results }
  end
  context "when paginated_results is defined" do
    let(:paginated_results){ mock :paginated_results }
    subject{ Yeti::Search.new context, {} }
    before{ subject.stub(:paginated_results).and_return paginated_results }
    it{ should delegates(:page_count).to :paginated_results }
    it{ should delegates(:count).to "paginated_results#pagination_record_count" }
    it{ should delegates(:results).to "paginated_results#all" }
  end
end
