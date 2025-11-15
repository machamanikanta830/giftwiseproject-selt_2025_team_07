Feature: Event management
<<<<<<< Updated upstream
  As a logged in user
  I want to create events
  So that I can plan gifts for special occasions

  Background:
    Given a user exists with email "test@example.com" and password "password"
    And I am logged in as "test@example.com" with password "password"

  Scenario: Create event with all fields filled
    Given I am on the new event page
    When I fill in the event form with valid data
    And I submit the event form
    Then I should be on the dashboard
    And I should see a success message for the event "Mom's Birthday Party"
    And my events count should be "1"

  Scenario: Create event with only required fields
    Given I am on the new event page
    When I fill in the event form with only required fields
    And I submit the event form
    Then I should be on the dashboard
    And I should see a success message for the event "Team Meeting"

  Scenario: Fail to create event without name
    Given I am on the new event page
    When I fill in the event form without a name
    And I submit the event form
    Then I should see an event validation error containing "Event name"
    And I should still be on the new event page

  Scenario: Fail to create event without date
    Given I am on the new event page
    When I fill in the event form without a date
    And I submit the event form
    Then I should see an event validation error containing "Event date"
    And I should still be on the new event page

  Scenario: Fail to create event with past date
    Given I am on the new event page
    When I fill in the event form with a past date
    And I submit the event form
    Then I should see an event validation error containing "cannot be in the past"
    And I should still be on the new event page

  Scenario: Fail to create event with negative budget
    Given I am on the new event page
    When I fill in the event form with a negative budget
    And I submit the event form
    Then I should see an event validation error containing "greater than or equal to 0"
    And I should still be on the new event page

  Scenario: Require login to access new event page
    Given I am logged out
    When I visit the new event page directly
    Then I should be on the login page
    And I should see "Please log in to continue"
=======
  As a logged-in user
  I want to create events
  So that I can plan gifts for upcoming occasions

  Background:
    Given a user exists with email "user@example.com" and password "password"
    And I am logged in as "user@example.com" with password "password"

  Scenario: Create event with all fields filled
    When I visit the new event page
    And I fill in the event form with:
      | Event Name   | Mom's Birthday Party                |
      | Event Date   | future date                         |
      | Location     | Home                                |
      | Budget       | 500                                 |
      | Description  | Surprise birthday celebration for mom |
    And I click "Create Event"
    Then I should be on the dashboard page
    And I should see "Event 'Mom's Birthday Party' created successfully!"

  Scenario: Create event with only required fields
    When I visit the new event page
    And I fill in the event form with:
      | Event Name | Team Meeting  |
      | Event Date | tomorrow      |
    And I click "Create Event"
    Then I should be on the dashboard page
    And I should see "Event 'Team Meeting' created successfully!"

  Scenario: Fail to create event without event name
    When I visit the new event page
    And I fill in the event form with:
      | Event Name |             |
      | Event Date | tomorrow    |
    And I click "Create Event"
    Then I should see "Event name can't be blank"

  Scenario: Fail to create event with past date
    When I visit the new event page
    And I fill in the event form with:
      | Event Name | Past Event   |
      | Event Date | yesterday    |
    And I click "Create Event"
    Then I should see "Event date cannot be in the past"
>>>>>>> Stashed changes
