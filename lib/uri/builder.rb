# frozen_string_literal: true

require_relative "builder/version"
require "uri"

module URI
  module Builder
    class Error < StandardError; end

    class Path
      File = ::File

      SLASH = "/".freeze

      def initialize(*segments, trailing: nil)
        @trailing = trailing
        @segments = segments
      end

      def join(*segments)
        self.class.new(*@segments, *segments, trailing: @trailing)
      end

      def parent
        @parent ||= self.class.new(*@segments[0...-1])
      end

      def root?
        @segments.empty?
      end

      def to_s
        File.join(SLASH, *@segments.map(&:to_s)).tap do |path|
          path.concat @trailing if @trailing and not root?
        end
      end

      def trailing(value = nil, slash: true)
        @trailing = value || slash ? SLASH : nil
        self
      end

      def self.parse(*segments)
        trailing = SLASH if segments.last.to_s.end_with?(SLASH)
        new(*flatten(segments), trailing:)
      end

      def self.flatten(segments)
        segments.compact.flat_map { _1.to_s.split(SLASH).reject(&:empty?) }
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

      def segments
        @uri.path.split("/").reject(&:empty?)
      end

      def join(*segments)
        path(*self.segments, *segments)
      end

      def path(*segments)
        if segments.empty?
          Path.parse(@uri.path)
        else
          wrap :path, Path.parse(*segments).to_s
        end
      end

      def root
        path Path::SLASH
      end
      alias :clear_path :root

      def trailing(value = nil)
        @trailing = value
        self
      end

      def trailing_slash
        wrap :path, Path.parse(@uri.path).trailing(slash: true).to_s
      end

      def clear_trailing_slash
        wrap :path, Path.parse(@uri.path).trailing(slash: false).to_s
      end

      def parent
        *parents, _ = segments

        if parents.any?
          path(*parents)
        else
          root
        end
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
