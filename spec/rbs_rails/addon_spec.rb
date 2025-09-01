# frozen_string_literal: true

require "ruby_lsp/global_state"
require "ruby_lsp/rbs_rails/addon"

RSpec.describe RubyLsp::RbsRails::Addon do
  describe "#activate" do
    subject { described_class.new.activate(global_state, message_queue) }

    let(:global_state) { instance_double(RubyLsp::GlobalState, workspace_path: workspace_path) }
    let(:message_queue) { Thread::Queue.new }

    context "when Rails application is not found" do
      let(:workspace_path) { "/" }

      it "skips activation" do
        subject

        log = message_queue.pop
        expect(log.params.message).to eq "rbs_rails: Rails application not found. Skip to activate rbs_rails addon."
      end
    end

    context "when Rails application found" do
      let(:workspace_path) { Pathname.new(__FILE__).dirname.join("../test-app/").expand_path.to_s }

      it "activates Rails app" do
        subject

        expect(message_queue).to be_empty
        expect(Rails.application).to be_a(Rails::Application)
      end
    end
  end
end
