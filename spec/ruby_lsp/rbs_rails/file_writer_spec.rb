# frozen_string_literal: true

RSpec.describe RubyLsp::RbsRails::FileWriter do
  describe "#write" do
    subject { file_writer.write(content) }

    after do
      tmpdir.rmtree
    end

    let(:file_writer) { described_class.new(path) }
    let(:path) { tmpdir / "test_file.rbs" }
    let(:tmpdir) { Pathname.new(Dir.mktmpdir("file_writer_test")) }

    context "when the file does not exist" do
      it "creates the file with the given content" do
        expect(path).not_to exist

        file_writer.write("class NewClass; end")

        expect(path).to exist
        expect(path.read).to eq("class NewClass; end")
      end
    end

    context "when the file exists" do
      before do
        path.write(old_content)
      end

      let(:old_content) { "class ExistingClass; end" }

      context "when the content is different" do
        it "updates the file with the new content" do
          file_writer.write("class NewClass; end")

          expect(path).to exist
          expect(path.read).to eq("class NewClass; end")
        end
      end

      context "when the content is the same" do
        before do
          path.utime(mtime, mtime)
        end

        let(:mtime) { Time.zone.now - 60 }

        it "does not modify the file" do
          file_writer.write(old_content)

          expect(path).to exist
          expect(path.read).to eq(old_content)
          expect(path.mtime).to eq(mtime)
        end
      end
    end
  end
end
