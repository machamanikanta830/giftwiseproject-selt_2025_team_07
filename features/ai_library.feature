Feature: AI Gift Library scopes and filters

  Background:
    Given I am logged in as "owner@example.com"
    And there is an owned event with AI ideas for "owner@example.com"
    And there is a collaboration event accessible to "owner@example.com" with AI ideas from "other@example.com"

  Scenario: Switching to Collab scope shows only collaboration events
    When I visit the AI Gift Library page
    And I click "Collab"
    Then I should see "Collab Event"
    And I should not see "Owned Event"

  Scenario: Collab scope shows collaboration event title
    When I visit the AI Gift Library page
    And I click "Collab"
    Then I should see "Collab Event"

  Scenario: Category dropdown is hidden in Collab scope
    When I visit the AI Gift Library page
    And I click "Collab"
    Then I should not see "Category"

  Scenario: Mine scope shows only my owned events
    When I visit the AI Gift Library page
    And I click "Mine"
    Then I should see "Owned Event"
    And I should not see "Collab Event"

  Scenario: All scope shows both owned and collaboration events
    When I visit the AI Gift Library page
    And I click "All"
    Then I should see "Owned Event"
    And I should see "Collab Event"
