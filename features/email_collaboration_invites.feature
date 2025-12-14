Feature: Collaboration invites by email (in-app only)
  As an event owner
  I want to invite collaborators by email
  So existing GiftWise users can help plan my event

  Background:
    Given the following users exist:
      | name        | email             | password     |
      | Alice Owner | alice@example.com | Password123! |
      | Bob Helper  | bob@example.com   | Password123! |
    And I am logged in as "alice@example.com" with password "Password123!"
    And I have created an event called "Summer BBQ" on "2025-07-15"

  Scenario: Event owner invites an existing user by email
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "bob@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    Then I should see "Bob Helper has been invited (in-app notification)."
    And I should see "bob@example.com – awaiting acceptance (Co-Planner)"

  Scenario: Cannot invite the same email twice
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "bob@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    Then I should see "Bob Helper has been invited (in-app notification)."
    When I fill in "collaborator[email]" with "bob@example.com"
    And I select "Viewer" from "collaborator[role]"
    And I press "Invite"
    Then I should see "That user is already a collaborator."

  Scenario: Non-user cannot be invited by email yet
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "charlie@example.com"
    And I select "Viewer" from "collaborator[role]"
    And I press "Invite"
    Then I should see "must already have a GiftWise account for now"
