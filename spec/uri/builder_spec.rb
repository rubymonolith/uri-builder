# frozen_string_literal: true

RSpec.describe URI::Builder::DSL do
  let(:dsl) { URI.build("https://example.com/foo/bar?fizz=buzz#super") }
  let(:uri) { dsl.uri }

  describe "#host" do
    before { dsl.host("www.example.com") }
    subject { uri.host }
    it { is_expected.to eql "www.example.com" }
  end

  describe "#scheme" do
    before { dsl.scheme("http") }
    subject { uri.scheme }
    it { is_expected.to eql "http" }
  end

  describe "#path" do
    let(:path) { "/fizz/buzz" }
    before { dsl.path(path) }
    subject { uri.path }
    it { is_expected.to eql "/fizz/buzz" }
    context "without leading /" do
      let(:path) { "fizz/buzz" }
      it { is_expected.to eql "/fizz/buzz" }
    end
    context "blank" do
      let(:path) { "" }
      it { is_expected.to eql "/" }
    end
  end

  describe "#query" do
    before { dsl.query(foo: "bar") }
    subject { uri.query }
    it { is_expected.to eql "foo=bar" }
  end

  describe "#fragment" do
    before { dsl.fragment("duper") }
    subject { uri.fragment }
    it { is_expected.to eql "duper" }
  end

  describe "#port" do
    before { dsl.port(9000) }
    subject { uri.port }
    it { is_expected.to eql 9000 }
  end
end
