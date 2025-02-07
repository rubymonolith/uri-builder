# frozen_string_literal: true

require_relative "builder/version"
require "uri"

module URI
  module Builder
    class Error < StandardError; end

    class Path
      File = ::File

      def initialize(*segments)
        @trailing_slash = segments.last.to_s.end_with?("/")
        @segments = segments.compact.flat_map { _1.to_s.split("/") }
      end

      def to_s
        File.join("/", *@segments.map(&:to_s).tap { _1.append "/" if @trailing_slash })
      end

      def trailing_slash(value = true)
        @trailing_slash = value
        self
      end
    end

    class DSL
      attr_reader :uri

      def initialize(uri)
        @uri = uri.clone
      end

      [:host, :fragment, :port].each do |property|
        define_method property do |value|
          wrap property, value
        end
      end

      def clear_fragment
        wrap :fragment, nil
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
        self
      end

      def query(value)
        value = case value
        when Hash, Array
          build_query value
        else
          value
        end

        wrap :query, value
      end

      def clear_query
        wrap :query, nil
      end

      def path(*segments)
        # Make sure there's a leading / if a non leading / is given.
        wrap :path, Path.new(*segments).to_s
      end

      def clear_path
        path "/"
      end

      def trailing_slash
        wrap :path, Path.new(@uri.path).trailing_slash(true).to_s
      end

      def clear_trailing_slash
        wrap :path, Path.new(@uri.path).trailing_slash(false).to_s
      end

      def to_s
        uri.to_s
      end

      def to_str
        uri.to_str
      end

      private
        def wrap(property, value)
          @uri.send "#{property}=", value
          self
        end

        def build_query(params, prefix = nil)
          case params
          when Hash
            params.map { |key, value|
              new_prefix = prefix ? "#{prefix}[#{key}]" : key.to_s
              build_query(value, new_prefix)
            }.reject(&:empty?).join('&')
          when Array
            params.map.with_index { |value, _index|
              new_prefix = "#{prefix}[]"
              build_query(value, new_prefix)
            }.reject(&:empty?).join('&')
          else
            "#{prefix}=#{URI.encode_www_form_component(params.to_s)}"
          end
        end
    end
  end

  def build
    Builder::DSL.new self
  end

  def self.build(value)
    if block_given?
      URI(value).build.tap do |uri|
        yield uri
      end.uri
    else
      URI(value).build
    end
  end

  def self.env(key, default = nil)
    build ENV.fetch key, default
  end
end
