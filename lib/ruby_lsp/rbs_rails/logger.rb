# frozen_string_literal: true

require "language_server/protocol"
require "ruby_lsp/utils"

module RubyLsp
  module RbsRails
    class Logger
      attr_reader :message_queue #: Thread::Queue

      # @rbs message_queue: Thread::Queue
      def initialize(message_queue) #: void
        @message_queue = message_queue
      end

      # @rbs message: String
      def info(message) #: void
        message_queue << Notification.window_log_message("rbs_rails: #{message}")
      end
    end
  end
end
