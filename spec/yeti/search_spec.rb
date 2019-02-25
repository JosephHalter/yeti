require "spec_helper"

describe Yeti::Search do
  let(:context){ double :context }
  context "initialization" do
    it "does require a context and a hash" do
      message = "wrong number of arguments (given 1, expected 2)"
      expect do
        Yeti::Search.new context
      end.to raise_error ArgumentError, message
    end
  end
  context "given context and an empty hash" do
    subject{ Yeti::Search.new context, {} }
    it "keeps given context" do
      expect(subject.context).to be context
    end
    it "#search defaults to {}" do
      expect(subject.search).to eq({})
    end
    it "#page defaults to 1" do
      expect(subject.page).to eq(1)
    end
    it "#per_page defaults to 20" do
      expect(subject.per_page).to eq(20)
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
    let(:results){ double :results }
    subject{ Yeti::Search.new context, search: search }
    before{ allow(subject).to receive(:results).and_return results }
    it "#search comes from hash" do
      expect(subject.search).to eq(search)
    end
    it "gets common filters from search" do
      expect(subject).to respond_to(:name_contains)
      expect(subject).to respond_to(:popular_equals)
      expect(subject).to respond_to(:created_at_gte)
      expect(subject).to respond_to(:created_at_lte)
      expect(subject.name_contains).to eq("tony")
      expect(subject.popular_equals).to eq("1")
      expect(subject.created_at_gte).to eq("2001-01-01")
      expect(subject.created_at_lte).to eq("2002-01-01")
    end
    it "doesn't get everything from search" do
      expect(subject).not_to respond_to(:uncommon_filter)
      expect{ subject.invalid_method }.to raise_error NoMethodError
      expect{ subject.uncommon_filter }.to raise_error NoMethodError
    end
    it "#page comes from hash" do
      expect(Yeti::Search.new(context, page: "2").page).to be 2
    end
    it "doesn't accept page to be lower than 1" do
      expect(Yeti::Search.new(context, page: "0").page).to be 1
    end
    it "#per_page comes from hash" do
      expect(Yeti::Search.new(context, per_page: "10").per_page).to be 10
    end
    it "doesn't accept per_page to be lower than 1" do
      expect(Yeti::Search.new(context, per_page: "0").per_page).to be 1
    end
    it "by default per_page has no limit" do
      expect(Yeti::Search.max_per_page).to be_nil
      expect(Yeti::Search.new(context, per_page: "9999").per_page).to be 9999
    end
    it "per_page can be limited" do
      search_class = Class.new Yeti::Search do
        max_per_page 50
      end
      expect(search_class.max_per_page).to be 50
      expect(search_class.new(context, per_page: "9999").per_page).to be 50
    end
    it "#paginated_results is virtual" do
      expect do
        subject.paginated_results
      end.to raise_error NotImplementedError
    end
    it{ is_expected.to delegates(:to_ary).to :results }
    it{ is_expected.to delegates(:empty?).to :results }
    it{ is_expected.to delegates(:each).to :results }
    it{ is_expected.to delegates(:group_by).to :results }
    it{ is_expected.to delegates(:size).to :results }
  end
  context "when paginated_results is defined" do
    let(:paginated_results){ double :paginated_results }
    subject{ Yeti::Search.new context, {} }
    before{ allow(subject).to receive(:paginated_results).and_return paginated_results }
    it{ is_expected.to delegates(:page_count).to :paginated_results }
    it{ is_expected.to delegates(:count).to "paginated_results#pagination_record_count" }
    it{ is_expected.to delegates(:results).to "paginated_results#all" }
  end
end
