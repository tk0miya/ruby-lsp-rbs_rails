# frozen_string_literal: true

require "language_server-protocol"
require "ruby_lsp/addon"

require_relative "logger"

module RubyLsp
  module RbsRails
    class Addon < ::RubyLsp::Addon
      include LanguageServer::Protocol::Constant

      attr_reader :global_state #: GlobalState
      attr_reader :logger #: Logger

      # @rbs global_state: GlobalState
      # @rbs message_queue: Thread::Queue
      def activate(global_state, message_queue) #: void
        @global_state = global_state
        @logger = Logger.new(message_queue)

        load_application
        load_rbs_rails_config
      rescue LoadError
        logger.info("Rails application not found. Skip to activate rbs_rails addon.")
      end

      def deactivate #: void
      end

      def name #: String
        "ruby-lsp-rbs_rails"
      end

      def version #: String
        VERSION
      end

      # @rbs! type fileChangeTypes = FileChangeType::CREATED | FileChangeType::CHANGED | FileChangeType::DELETED

      # @rbs changes: Array[{ uri: String, type: fileChangeTypes }]
      def workspace_did_change_watched_files(changes) #: void
        return unless defined?(::Rails)

        ::Rails.application.reloader.wrap do
          changes.each do |change|
            case change[:type]
            when FileChangeType::CREATED, FileChangeType::CHANGED
              generate_signature(change[:uri])
            when FileChangeType::DELETED
              delete_signature(change[:uri])
            end
          end
        end
      end

      private

      # @rbs @workspace_path: Pathname?

      def workspace_path #: Pathname
        @workspace_path ||= Pathname.new(global_state.workspace_path)
      end

      # Load Rails application and enable reloading
      def load_application #: void
        require_relative workspace_path.join("config/application").to_s

        install_hooks

        ::Rails.application.initialize! unless ::Rails.application.initialized?
        ::Rails.env = "development"
        ::Rails.autoloaders.main.enable_reloading
      end

      def install_hooks #: void
        require "rbs_rails/active_record/enum"
      end

      def load_rbs_rails_config #: void
        # Load rbs_rails lazily (after install hooks)
        require "rbs_rails"
        require "rbs_rails/cli/configuration"

        if workspace_path.join(".rbs_rails.rb").exist?
          load workspace_path.join(".rbs_rails.rb").to_s
        elsif workspace_path.join("config/rbs_rails.rb").exist?
          load workspace_path.join("config/rbs_rails.rb").to_s
        end
      end

      def config #: ::RbsRails::CLI::Configuration
        ::RbsRails::CLI::Configuration.instance
      end

      # @rbs uri: String
      def generate_signature(uri) #: void
        path = uri_to_path(uri)
        return unless path

        case path.to_s
        when "db/schema.rb"
          generate_all_model_signatures
        when %r{^config/(routes\.rb|routes/.*\.rb)$}
          generate_path_helpers_signature
        else
          klass = constantize(path)
          return unless klass

          generate_signature0(klass)
        end
      rescue StandardError => e
        logger.info("Failed to generate signature for #{path}: #{e.message}")
      end

      def generate_all_model_signatures #: void
        ::Rails.application.eager_load!
        ::ActiveRecord::Base.descendants.each do |klass|
          generate_signature0(klass)
        end
      end

      def generate_path_helpers_signature #: void
        rbs_path = config.signature_root_dir / "path_helpers.rbs"
        rbs_path.dirname.mkpath

        sig = ::RbsRails::PathHelpers.generate
        rbs_path.write sig
        logger.info("Updated RBS signature: #{rbs_path}")
      end

      # @rbs klass: Class
      def generate_signature0(klass) #: void
        return unless klass < ::ActiveRecord::Base
        return if config.ignored_model?(klass)
        return unless ::RbsRails::ActiveRecord.generatable?(klass)

        rbs_path = get_rbs_path_for_model(klass)
        rbs_path.dirname.mkpath

        sig = ::RbsRails::ActiveRecord.class_to_rbs(klass)
        rbs_path.write sig
        logger.info("Updated RBS signature: #{rbs_path}")
      end

      # @rbs uri: String
      def delete_signature(uri) #: void
        path = uri_to_path(uri)
        return unless path
        return unless path.extname == ".rb"

        rbs_path = config.signature_root_dir / path.sub_ext(".rbs")
        return unless rbs_path.exist?

        rbs_path.delete
        logger.info("Deleted RBS signature: #{rbs_path}")
      rescue StandardError => e
        logger.info("Failed to delete signature for #{path}: #{e.message}")
      end

      # @rbs uri: String
      def uri_to_path(uri) #: Pathname?
        path = uri.delete_prefix("file://")

        # Ignore if the given path is not under Rails.root
        return nil unless path.start_with?(::Rails.root.to_s + File::SEPARATOR)

        Pathname.new(path).relative_path_from(::Rails.root)
      end

      # @rbs path: Pathname
      def constantize(path) #: Class?
        # If the specified file is placed under autoload_paths
        ::Rails.application.config.autoload_paths.each do |autoload_path|
          # @type var autoload_path: String
          next unless path.to_s.start_with?(autoload_path + File::SEPARATOR)

          relative_path = path.relative_path_from(autoload_path)
          return relative_path.to_s.chomp(".rb").classify.constantize
        end

        # If not, the file must be placed under app/*/ directories
        relative_path = path.to_s.sub(%r{^app/.*?/}, "")
        relative_path.chomp(".rb").classify.constantize
      rescue NameError
        nil
      end

      # @rbs klass: Class
      def get_rbs_path_for_model(klass) #: Pathname
        path, _line = begin
          Object.const_source_location(klass.name)
        rescue StandardError
          nil
        end

        rbs_path = if path && Pathname.new(path).fnmatch?("#{::Rails.root}/**")
                     Pathname.new(path).relative_path_from(::Rails.root).sub_ext(".rbs")
                   else
                     "app/models/#{klass.name.underscore}.rbs"
                   end

        config.signature_root_dir / rbs_path
      end
    end
  end
end
