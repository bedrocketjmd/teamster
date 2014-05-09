require 'jbuilder'
require 'sprockets'
require 'uglifier'
require 'aws-sdk'
require 'cssminify'
require 'mime/types'

require_relative 'package'

module Teamster

  module Configuration

    class Base

      def self.define_attribute( attribute_name, options = {} )
        class_eval(
                   "def #{attribute_name}( *arguments ); " +
                   "@#{attribute_name} = arguments.first unless arguments.empty?; " +
                   "if !@#{attribute_name}.nil?;" +
                     "@#{attribute_name};" +
                   "else;" +
                   ( ( options[:default].nil?  ) ?
                     "nil" :
                     ( options[ :default ].is_a?( String ) ?
                       "'#{options[ :default ]}'" :
                       "#{options[ :default ]}" ) ) + ";" +
                   "end;" +
                   "end",
                   __FILE__,
                   __LINE__
                   )

      end

    end

    class Package < Base

      attr_reader :asset_paths
      attr_reader :target_service_uri
      attr_reader :target_service_configuration
      attr_reader :dynamic_files

      def initialize( &block )
        @asset_paths = []
        @dynamic_files = []
        @app_paths = []
        self.instance_eval( &block ) if block_given?
      end

      def javascripts( &block )
        self.instance_eval( &block ) if block_given?
      end

      def stylesheets( &block )
        self.instance_eval( &block ) if block_given?
      end

      define_attribute :concatenate,  default: false
      define_attribute :compress,     default: false
      define_attribute :location,     default: 'tmp/teamster'
      define_attribute :digest,       default: true
      define_attribute :cdn_uri
      define_attribute :api_uri

      def deploy_to( uri, &block )
        @target_service_uri = uri
        @target_service_configuration = S3.new
        @target_service_configuration.instance_eval( &block ) if block_given?
      end

      define_attribute :host
      define_attribute :copy_files
      define_attribute :max_age
      define_attribute :app_paths

      def directory( dir )
        @asset_paths << dir unless @asset_paths.include?( dir )
      end

      def copy_files(*arguments, &block)
        self.instance_eval( &block ) if block_given?
      end

      def file( *arguments, &block )
        @dynamic_files << begin
                            dynamic_file = DynamicFile.new(
                                                           arguments.shift,
                                                           arguments.first.is_a?( Hash ) ? arguments.shift : {}
                                                           )
                            dynamic_file.content = arguments.first
                            dynamic_file.build( &block ) if block_given?
                            dynamic_file
                          end
      end

      def pack
        @package = ::Package.new(self)
        @package.pack
      end

      def deploy
        @package.deploy
      end
    end

    class S3 < Base
      define_attribute :access_key_id
      define_attribute :secret_access_key
    end

    class DynamicFile

      attr_reader   :path
      attr_accessor :content

      def initialize( path, options = {} )
        @path = path
        @options = options
      end

      def build( &block )
        file_format = @options[ :format ].to_s || 'json'
        throw "The file format #{file_format} is no supported." \
        unless file_format == 'json'
          @content = Jbuilder.encode( &block )
        end

      end

    end

  end
