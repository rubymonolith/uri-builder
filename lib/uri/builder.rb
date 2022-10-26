# frozen_string_literal: true

require_relative "builder/version"
require "uri"

module URI
  module Builder
    class Error < StandardError; end

    class DSL
      attr_reader :uri

      def initialize(uri)
        @uri = uri.clone
      end

      [:host, :scheme, :query, :fragment, :port].each do |property|
        define_method property do |value|
          wrap property, value
        end
      end

      def query(value)
        value = case value
        when Hash
          URI.encode_www_form value
        else
          value
        end

        wrap :query, value
      end

      def path(value)
        # Make sure there's a leading / if a non leading / is given.
        wrap :path, ::File.join("/", value)
      end

      def to_s
        uri.to_s
      end

      private
        def wrap(property, value)
          @uri.send "#{property}=", value
          self
        end
    end
  end

  def build
    Builder::DSL.new self
  end

  def self.build(value)
    URI(value).build
  end

  def self.env(key, default = nil)
    build ENV.fetch key, default
  end
end
