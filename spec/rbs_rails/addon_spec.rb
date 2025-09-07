# frozen_string_literal: true

require "ruby_lsp/global_state"
require "ruby_lsp/rbs_rails/addon"

include LanguageServer::Protocol::Constant # rubocop:disable Style/MixinUsage

RSpec.describe RubyLsp::RbsRails::Addon do
  before :all do
    test_app_path = Pathname.new(__FILE__).dirname.join("../test-app/").expand_path.to_s
    system("bundle exec rails db:migrate", chdir: test_app_path, exception: true)
  end

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

  describe "#workspace_did_change_watched_files" do
    subject { addon.workspace_did_change_watched_files(changes) }

    before { addon.activate(global_state, message_queue) }

    after do
      signature_path = Pathname.new("#{workspace_path}/sig/rbs_rails")
      signature_path.rmtree if signature_path.exist?

      RbsRails::CLI::Configuration.instance.send(:initialize)
    end

    let(:addon) { described_class.new }
    let(:global_state) { instance_double(RubyLsp::GlobalState, workspace_path: workspace_path) }
    let(:message_queue) { Thread::Queue.new }
    let(:workspace_path) { Pathname.new(__FILE__).dirname.join("../test-app/").expand_path.to_s }

    context "when file created event is received" do
      let(:changes) do
        [
          { uri: "file://#{workspace_path}/#{filename}", type: FileChangeType::CREATED }
        ]
      end

      context "when a model file is created" do
        let(:filename) { "app/models/user.rb" }
        let(:rbs_path) { Pathname.new("#{workspace_path}/sig/rbs_rails/app/models/user.rbs") }

        context "when the model is not ignored" do
          it "generates the corresponding RBS file" do
            subject

            expect(rbs_path).to exist
            content = rbs_path.read
            expect(content).to include("class ::User")
            expect(content).to include("def name: () -> ::String?")
          end
        end

        context "when the model is ignored" do
          before do
            RbsRails::CLI::Configuration.instance.ignore_model_if { |klass| klass.name == "User" }
          end

          it "generates no RBS files" do
            subject

            rbs_files = Pathname.new("#{workspace_path}/sig/").glob("**/*.rbs")
            expect(rbs_files).to be_empty
          end
        end

        context "when the model is abstract" do
          let(:filename) { "app/models/application_record.rb" }

          it "generates no RBS files" do
            subject

            rbs_files = Pathname.new("#{workspace_path}/sig/").glob("**/*.rbs")
            expect(rbs_files).to be_empty
          end
        end
      end

      context "when db/schema.rb is created" do
        let(:filename) { "db/schema.rb" }

        it "generates RBS files for all models" do
          subject

          rbs_files = Pathname.new("#{workspace_path}/sig/").glob("**/*.rbs").map(&:to_s)
          expect(rbs_files).to contain_exactly("#{workspace_path}/sig/rbs_rails/app/models/user.rbs",
                                               "#{workspace_path}/sig/rbs_rails/app/models/blog.rbs")
        end
      end

      context "when config/routes.rb is created" do
        let(:filename) { "config/routes.rb" }
        let(:rbs_path) { Pathname.new("#{workspace_path}/sig/rbs_rails/path_helpers.rbs") }

        it "generates path_helpers.rbs" do
          subject

          expect(rbs_path).to exist
          content = rbs_path.read
          expect(content).to include("interface ::_RbsRailsPathHelpers")
        end
      end

      context "when config/routes/*.rb is created" do
        let(:filename) { "config/routes/api.rb" }
        let(:rbs_path) { Pathname.new("#{workspace_path}/sig/rbs_rails/path_helpers.rbs") }

        it "generates path_helpers.rbs" do
          subject

          expect(rbs_path).to exist
          content = rbs_path.read
          expect(content).to include("interface ::_RbsRailsPathHelpers")
        end
      end

      context "when any other file is created" do
        let(:filename) { "app/controllers/users_controller.rb" }

        it "generates no RBS files" do
          subject

          rbs_files = Pathname.new("#{workspace_path}/sig/").glob("**/*.rbs")
          expect(rbs_files).to be_empty
        end
      end
    end

    context "when file changed event is received" do
      let(:changes) do
        [
          { uri: "file://#{workspace_path}/app/models/user.rb", type: FileChangeType::CHANGED }
        ]
      end
      let(:rbs_path) { Pathname.new("#{workspace_path}/sig/rbs_rails/app/models/user.rbs") }

      it "generates the corresponding RBS file" do
        subject

        expect(rbs_path).to exist
        content = rbs_path.read
        expect(content).to include("class ::User")
        expect(content).to include("def name: () -> ::String?")
      end
    end

    context "when file deleted event is received" do
      let(:changes) do
        [
          { uri: "file://#{workspace_path}/app/models/user.rb", type: FileChangeType::DELETED }
        ]
      end
      let(:rbs_path) { Pathname.new("#{workspace_path}/sig/rbs_rails/app/models/user.rbs") }

      context "when the RBS file corresponding to the deleted Ruby file exists" do
        before do
          rbs_path.parent.mkpath
          rbs_path.write("") # Create a dummy RBS file
        end

        it "deletes the corresponding RBS file" do
          subject

          expect(rbs_path).not_to exist
        end
      end

      context "when the RBS file corresponding to the deleted Ruby file does not exist" do
        it "does not raise an error" do
          subject

          expect(rbs_path).not_to exist
        end
      end
    end
  end
end
