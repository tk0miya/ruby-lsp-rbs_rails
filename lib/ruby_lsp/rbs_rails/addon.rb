# frozen_string_literal: true

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
      end

      def deactivate #: void
      end

      def name #: String
        "ruby-lsp-rbs_rails"
      end

      def version #: String
        VERSION
      end
    end
  end
end
