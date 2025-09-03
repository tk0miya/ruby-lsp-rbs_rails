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
              # TODO
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
    end
  end
end
