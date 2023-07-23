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

      [:host, :query, :fragment, :port].each do |property|
        define_method property do |value|
          wrap property, value
        end
      end

      def scheme(value)
        if @uri.scheme
          # Handles URLs without schemes, like https://example.com/foo
          target_scheme = URI.scheme_list[value.upcase]
          args = Hash[target_scheme.component.map { |attr| [ attr, @uri.send(attr) ] }]
          @uri = target_scheme.build(**args)
        else
          # Handles URLs without schemes, like example.com/foo
          uri = URI.parse("#{value}://#{@uri.path}")
          (uri.component - %i[host path scheme]).each do |component|
            uri.send "#{component}=", @uri.send(component)
          end
          @uri = uri
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

      def path(*segments)
        # Make sure there's a leading / if a non leading / is given.
        wrap :path, ::File.join(*segments.compact.map(&:to_s).prepend("/"))
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
