# frozen_string_literal: true

module RubyLsp
  module RbsRails
    class Addon < ::RubyLsp::Addon
      attr_reader :global_state #: GlobalState
      attr_reader :message_queue #: Thread::Queue

      # @rbs global_state: GlobalState
      # @rbs message_queue: Thread::Queue
      def activate(global_state, message_queue) #: void
        @global_state = global_state
        @message_queue = message_queue
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
