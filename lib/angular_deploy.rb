require 'sprockets'
require 'uglifier'
require 'pry'

require_relative 'builder'
require_relative 'sprockets'

module AngularDeploy

  class Configs

    def initialize(&block)
      @settings = Config.new
      @settings.instance_eval(&block) if block_given?
      @deploy_dir = './tmp/angular_deploy'
      @builder = Builder.new(@settings, @sprockets, @deploy_dir)
    end

    def package(config_name, &block)
      @settings.instance_eval(&block) if block_given?
      @settings
    end

    def build_files
      @builder.build_files
    end

    def upload_to_s3
      @builder.upload_to_s3
    end
  end

  class Config
    def initialize
      @groups = {}
      @settings = {}
    end

    def group(name, &block)
      group = (@groups[name] ||= Config.new)
      group.instance_eval(&block) if block_given?
      define_accessor(name) { group }
    end

    def set(key, value)
      define_accessor(key) { value }
      @settings[key] = value
    end

    private

    def define_accessor(name, &block)
      AngularDeploy::Config.class_eval { define_method(name, &block) }
    end
  end

end
