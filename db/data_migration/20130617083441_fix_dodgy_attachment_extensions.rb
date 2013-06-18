
puts "Repairing attachments with double file extensions"
AttachmentUploader::EXTENSION_WHITE_LIST.each do |ext|
  files = AttachmentData.where("replaced_by_id IS NULL and carrierwave_file LIKE \"%.#{ext}.#{ext}\"")
  puts "Checking extension '#{ext}' - found #{files.count} attachment(s)"

  DataHygiene::AttachmentExtensionFixer.fix_attachment_data(files)
end
