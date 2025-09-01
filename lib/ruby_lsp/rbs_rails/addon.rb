# frozen_string_literal: true

require "ruby_lsp/addon"

require_relative "logger"

module RubyLsp
  module RbsRails
    class Addon < ::RubyLsp::Addon
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
    end
  end
end
