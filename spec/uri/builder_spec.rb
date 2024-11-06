# frozen_string_literal: true

RSpec.describe URI::Builder::DSL do
  let(:builder) { URI.build("https://example.com/foo/bar?fizz=buzz#super") }
  let(:uri) { builder.uri }

  describe ".build" do
    context "block given" do
      subject do
        URI.build("example.com") do |u|
          u.scheme "https"
          u.path "/about"
        end
      end
      it "returns URI" do
        expect(subject).to be_a URI
      end
      it "modifies URI" do
        expect(subject.to_s).to eql "https://example.com/about"
      end
    end
    context "no block given" do
      subject do
        URI.build("example.com")
      end
      it "returns URI::Builder" do
        expect(subject).to be_a URI::Builder::DSL
      end
    end
  end

  describe "#host" do
    before { builder.host("www.example.com") }
    subject { uri.host }
    it { is_expected.to eql "www.example.com" }
  end

  describe "#scheme" do
    before { builder.scheme("https") }
    describe "value" do
      subject { uri.scheme }
      it { is_expected.to eql "https" }
    end
    describe "class" do
      subject { uri.class }
      it { is_expected.to eql URI::HTTPS }
    end
    context "generic" do
      let(:builder) { URI.build("example.com/foo/bar?fizz=buzz#super") }
      subject { uri.to_s }
      it { is_expected.to eql "https://example.com/foo/bar?fizz=buzz#super" }
    end
  end

  describe "#path" do
    let(:path) { "/fizz/buzz" }
    before { builder.path(*path) }
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
    context "nil" do
      let(:path) { nil }
      it { is_expected.to eql "/" }
    end
    context "23" do
      let(:path) { 23 }
      it { is_expected.to eql "/23" }
    end
    context "[nil, 23, '', :dog]" do
      let(:path) { [ nil, 23, '', :dog ] }
      it { is_expected.to eql "/23/dog" }
    end
  end

  describe "#trailing_slash" do
    before { builder.path(*path).trailing_slash }
    subject { uri.path }
    context "/fizz/buzz" do
      let(:path) { "/fizz/buzz" }
      it { is_expected.to eql "/fizz/buzz/" }
    end
    context "/fizz/buzz/" do
      let(:path) { "/fizz/buzz/" }
      it { is_expected.to eql "/fizz/buzz/" }
    end
    context "/" do
      let(:path) { "/" }
      it { is_expected.to eql "/" }
    end
  end

  describe "#query" do
    before { builder.query(foo: "bar") }
    subject { uri.query }
    it { is_expected.to eql "foo=bar" }

    describe "nested hashes and arrays" do
      before {
        builder.query(
          foo: {
            bar: [
              {fizz: "buzz"},
              %w[a b c],
              "fun"
            ],
          }
        )
      }
      it { is_expected.to eql "foo[bar][][fizz]=buzz&foo[bar][][]=a&foo[bar][][]=b&foo[bar][][]=c&foo[bar][]=fun" }
    end
  end

  describe "#fragment" do
    before { builder.fragment("duper") }
    subject { uri.fragment }
    it { is_expected.to eql "duper" }
  end

  describe "#port" do
    before { builder.port(9000) }
    subject { uri.port }
    it { is_expected.to eql 9000 }
  end

  describe "#to_str" do
    subject { uri.to_str }
    it { is_expected.to eql "https://example.com/foo/bar?fizz=buzz#super" }
  end
end
