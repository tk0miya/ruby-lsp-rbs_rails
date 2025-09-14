# frozen_string_literal: true

module RubyLsp
  module RbsRails
    # To avoid unnecessary type reloading by type checkers and other utilities,
    # FileWriter modifies the target file only if its content has been changed.
    #
    # See https://github.com/pocke/rbs_rails/pull/346
    class FileWriter
      attr_reader :path #: Pathname

      # @rbs path: Pathname
      def initialize(path) #: void
        @path = path
      end

      def write(content) #: void
        original_content = begin
          path.read
        rescue StandardError
          nil
        end

        return unless original_content != content

        path.write(content)
      end
    end
  end
end
