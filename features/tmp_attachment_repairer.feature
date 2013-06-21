Feature: Temporary feature to verify the attachment repairer does what it's supposed to

  As Tekin the developer
  I want to verify that repairing attachments does the right thing
  So I can be sure my code is doing what it's supposed to

  -----

  This only exists for now so that I can see, end-to-end, that my repair
  code is doing what is expected.

  Background:
    Given I am a GDS editor called "Jane"

  @quarantine-files
  Scenario: A repaired edition will link to the renamed attachment
    Given a published publication with a misnamed attachment exists
    And the attachment has been virus-checked
    When the document attachment repairer is run on that publication
    And the attachment has been virus-checked
    Then the public publication page should link to the renamed attachment
    And visiting the old attachment path redirects to the new attachment
