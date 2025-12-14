Feature: Email-based Collaboration Invites
  As an event owner
  I want to invite collaborators via email
  So they can help plan my event even if they're not in my friends list

  Background:
    Given the following users exist:
      | name        | email                  | password      |
      | Alice Owner | alice@example.com      | Password123!  |
      | Bob Helper  | bob@example.com        | Password123!  |
    And I am logged in as "alice@example.com" with password "Password123!"
    And I have created an event called "Summer BBQ" on "2025-07-15"

  Scenario: Event owner invites existing user via email
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "bob@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    Then I should see "Invite email sent to bob@example.com"
    And "bob@example.com" should receive an email with subject "Alice Owner invited you to collaborate on Summer BBQ"

  Scenario: Non-user receives invite and signs up to accept
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "charlie@example.com"
    And I select "Viewer" from "collaborator[role]"
    And I press "Invite"
    Then "charlie@example.com" should receive an email

    When "charlie@example.com" opens the email
    And they click the "Accept Invitation" link in the email
    Then they should see "Please log in or sign up to accept this collaboration invitation"
    And they should be on the login page

    When they click "Sign up"
    And they fill in the following:
      | user[name]                 | Charlie New    |
      | user[email]                | charlie@example.com |
      | user[password]             | Password123!   |
      | user[password_confirmation]| Password123!   |
    And they press "Create Account"
    Then they should see "you've successfully joined Summer BBQ"
    And they should be on the event page for "Summer BBQ"

  Scenario: Existing user accepts invite via email
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "bob@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    And I log out

    When "bob@example.com" opens the email
    And they click the "Accept Invitation" link in the email
    Then they should see "Please log in or sign up to accept this collaboration invitation"

    When they fill in "email" with "bob@example.com"
    And they fill in "password" with "Password123!"
    And they press "Log In"
    Then they should see "you've successfully joined Summer BBQ"
    And they should be on the event page for "Summer BBQ"

  Scenario: Invite expires after 14 days
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "old@example.com"
    And I select "Viewer" from "collaborator[role]"
    And I press "Invite"
    And 15 days pass

    When "old@example.com" opens the email
    And they click the "Accept Invitation" link in the email
    Then they should see "This invitation has expired"

  Scenario: Cannot invite same email twice
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "bob@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    Then I should see "Invite email sent to bob@example.com"

    When I fill in "collaborator[email]" with "bob@example.com"
    And I select "Viewer" from "collaborator[role]"
    And I press "Invite"
    Then I should see "An invite is already pending for bob@example.com"

  Scenario: Wrong email cannot accept invite
    When I visit the event page for "Summer BBQ"
    And I fill in "collaborator[email]" with "specific@example.com"
    And I select "Co-Planner" from "collaborator[role]"
    And I press "Invite"
    And I log out

    When "specific@example.com" opens the email
    And they click the "Accept Invitation" link in the email
    And they fill in "email" with "bob@example.com"
    And they fill in "password" with "Password123!"
    And they press "Log In"
    Then they should see "This invitation was sent to specific@example.com"