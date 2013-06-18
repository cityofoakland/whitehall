require 'test_helper'

module DataHygiene
  class AttachementExtensionFixerTest < ActiveSupport::TestCase

    test 'creates a replacement if the file has a double extension' do
      attachment_data = create(:attachment_data, file: double_extension_file)
      fixer = fixer_for(attachment_data)

      assert_equal attachment_data, fixer.attachment_data
      fixer.fix!

      assert replacement = attachment_data.reload.replaced_by
      assert replacement.is_a?(AttachmentData)
      assert replacement.persisted?
      assert File.exists?(replacement.file.path)
      assert_equal 'whitepaper.pdf', replacement.filename
      assert FileUtils.identical?(replacement.file.path, attachment_data.file.path)
    end

    test "does nothing if file's extension is ok" do
      attachment_data = create(:attachment_data)
      fixer = fixer_for(attachment_data)

      assert_no_difference('AttachmentData.count') do
        fixer.fix!
      end
      assert_nil attachment_data.reload.replaced_by
    end

    test 'does nothing if the attachment already has a replacement' do
      replacement = create(:attachment_data)
      attachment_data = create(:attachment_data, file: double_extension_file, replaced_by: replacement)
      fixer = fixer_for(attachment_data)

      assert_no_difference('AttachmentData.count') do
        fixer.fix!
      end

      assert_equal replacement, attachment_data.reload.replaced_by
    end

    test 'logs any attachments with missing files' do
      attachment_data = create(:attachment_data, file: double_extension_file)
      File.delete attachment_data.file.path
      logger = mock('logger', warn: "WARNING: File for AttachmentData (#{attachment_data.id}) not found (#{attachment_data.file.path})")
      fixer  = fixer_for(attachment_data, logger)

      fixer.fix!
    end

    test '#corrected_filename removes duplicate extensions' do
      fixer = fixer_for(create(:attachment_data, file: File.open(Rails.root.join('test', 'fixtures', 'whitepaper.pdf.pdf'))))
      assert_equal 'whitepaper.pdf', fixer.corrected_filename
    end

    test '#corrected_filename does not screw up correct filenames' do
      fixer = fixer_for(create(:attachment_data, file: File.open(Rails.root.join('test', 'fixtures', 'whitepaper.pdf'))))
      assert_equal 'whitepaper.pdf', fixer.corrected_filename
    end

    private

    def fixer_for(attachment_data, logger=nil)
      DataHygiene::AttachmentExtensionFixer.new(attachment_data, (logger || stub_everything("Logger")))
    end

    def double_extension_file
      File.open(Rails.root.join('test', 'fixtures', 'whitepaper.pdf.pdf'))
    end
  end
end
