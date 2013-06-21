class FakeLog
  def info(msg)
    puts msg
  end
  alias :warn :info
end
logger = FakeLog.new

Given /^a published publication with a misnamed attachment exists$/ do
  @bad_attachment = create(:attachment, file: File.open(Rails.root.join('test', 'fixtures', 'whitepaper.pdf.pdf')))
  @publication = create(  :publication, :published,
                          alternative_format_provider: create(:organisation_with_alternative_format_contact_email),
                          attachments: [@bad_attachment] )
  puts @bad_attachment.attachment_data.inspect
  puts @bad_attachment.attachment_data.file.path
  puts File.exists?(@bad_attachment.attachment_data.file.path)
end

When /^the document attachment repairer is run on that publication$/ do
 DataHygiene::DocumentAttachmentRepairer.new(@publication.document, gds_team_user, logger).repair_attachments!
end

Then /^the public publication page should link to the renamed attachment$/ do
  visit public_document_path(@publication)

  within record_css_selector(@bad_attachment) do
    assert page.has_content?(@bad_attachment.title)
    assert_match /whitepaper.pdf$/, page.find('h3 a')[:href]
  end
end

Then /^visiting the old attachment path redirects to the new attachment$/ do

end

def gds_team_user
  @gds_team_user ||= create(:gds_editor, name: "GDS Inside Government Team")
end
