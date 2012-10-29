# encoding: UTF-8

require 'test_helper'

class PublicationUploaderTest < ActiveSupport::TestCase
  setup do
    @log_buffer = StringIO.new
    @logger = Logger.new(@log_buffer)
  end

  test "should log a warning if the publication couldn't be saved" do
    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample(
        "body" => ""
      ),
      logger: @logger
    )

    uploader.upload

    assert_match /couldn't be saved for the following reasons/, @log_buffer.string
  end

  test "a minimally valid publication is created and the document_source is recorded" do
    importer = create(:user)
    csv_data = csv_sample(
      "old_url"          => "http://example.com",
      "title"            => "title",
      "summary"          => "summary",
      "body"             => "body",
      'publication_date' => '11/16/2011',
      'pub type'         => 'foi-releases'
    )
    uploader = PublicationUploader.new(
      import_as: importer,
      csv_data: csv_data,
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert_equal importer, publication.creator
    assert_equal "title", publication.title
    assert_equal "summary", publication.summary
    assert_equal "body", publication.body
    assert_equal Date.parse('2011-11-16'), publication.publication_date
    assert_equal PublicationType::FoiRelease, publication.publication_type
    assert_equal "http://example.com", publication.document.document_source.url
  end

  test "up to 3 policies specified by slug are associated with the edition" do
    policy_1 = create(:published_policy, title: "Policy 1")
    policy_2 = create(:published_policy, title: "Policy 2")
    policy_3 = create(:published_policy, title: "Policy 3")
    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample(
        "policy 1" => policy_1.slug,
        "policy 2" => policy_2.slug,
        "policy 3" => policy_3.slug
      ),
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert_equal [policy_1, policy_2, policy_3], publication.related_policies
  end

  test "organisation specified by name is associated with the edition" do
    organisation = create(:organisation)
    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample("org" => organisation.name),
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert_equal [organisation], publication.organisations
  end

  test "document series specified by slug is associated with the edition" do
    document_series = create(:document_series)
    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample("doc series" => document_series.slug),
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert_equal document_series, publication.document_series
  end

  test "up to 2 ministers specified by slug are used to find the roles to associate the publication to" do
    minister_1 = create(:person)
    minister_2 = create(:person)
    role_1 = create(:ministerial_role)
    role_2 = create(:ministerial_role)
    create(:role_appointment, role: role_1, person: minister_1)
    create(:role_appointment, role: role_2, person: minister_2)
    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample(
        "minister 1" => minister_1.slug,
        "minister 2" => minister_2.slug
      ),
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert_equal [role_1, role_2], publication.ministerial_roles
  end

  test "attachments are downloaded and associated to the publication" do
    stub_download("http://example.com/attachment-1.pdf", "two-pages.pdf")
    stub_download("http://example.com/attachment-2.csv", "sample-from-excel.csv")
    create(:organisation, name: "Department of Stuff", alternative_format_contact_email: "someone@example.com")

    uploader = PublicationUploader.new(
      import_as: create(:user),
      csv_data: csv_sample(
        "org" => "Department of Stuff",
        "attachment 1 title" => "first attachment",
        "attachment 1 url" => "http://example.com/attachment-1.pdf",
        "attachment 2 title" => "second attachment",
        "attachment 2 url" => "http://example.com/attachment-2.csv"
      ),
      logger: @logger
    )

    uploader.upload

    assert publication = Publication.first
    assert attachments = publication.attachments
    assert_equal 2, attachments.count
    assert_equal "first attachment", attachments[0].title
    assert_equal "http://example.com/attachment-1.pdf", attachments[0].attachment_source.url
    assert_equal File.read(Rails.root.join("test", "fixtures", "two-pages.pdf")), File.read(attachments[0].file.path)
    assert_equal "second attachment", attachments[1].title
    assert_equal "http://example.com/attachment-2.csv", attachments[1].attachment_source.url
    assert_equal File.read(Rails.root.join("test", "fixtures", "sample-from-excel.csv")), File.read(attachments[1].file.path)
  end

private
  def csv_sample(additional_fields = {}, extra_rows = [])
    data = minimally_valid_row.merge(additional_fields)
    lines = []
    lines << CSV.generate_line(data.keys, encoding: "UTF-8")
    lines << CSV.generate_line(data.values, encoding: "UTF-8")
    extra_rows.each do |row|
      lines << CSV.generate_line(default_row.merge(row).values, encoding: "UTF-8")
    end
    lines.join
  end

  def stub_download(url, fixture_file_name)
    file = File.new(Rails.root.join("test", "fixtures", fixture_file_name))
    stub_request(:get, url).to_return(body: file, status: 200)
  end

  def minimally_valid_row
    {
      "old_url"          => "http://example.com",
      "title"            => "title",
      "summary"          => "summary",
      "body"             => "body",
      "publication_date" => "11/16/2011",
      "pub type"         => "foi-releases"
    }
  end
end