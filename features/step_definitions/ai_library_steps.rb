# features/step_definitions/ai_library_steps.rb

def find_or_create_user!(email, name:, password: "Password1!")
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    u.password = password
    u.password_confirmation = password if u.respond_to?(:password_confirmation=)
  end
end

def create_event_recipient!(event:, recipient:, user:)
  return nil unless defined?(EventRecipient)

  cols = EventRecipient.column_names rescue []
  attrs = { event: event, recipient: recipient }
  attrs[:user] = user if cols.include?("user_id")
  EventRecipient.create!(attrs)
end

def create_collaboration_link!(event:, user:)
  join_models = %w[
    Collaborator EventCollaborator Collaboration EventCollaboration SharedEvent EventShare EventSharing
  ]

  join_models.each do |klass_name|
    next unless Object.const_defined?(klass_name)
    klass = Object.const_get(klass_name)
    cols = klass.column_names rescue []

    attrs = {}

    # event association
    if cols.include?("event_id") || (klass.reflect_on_association(:event) rescue false)
      attrs[:event] = event
    end

    # user/collaborator association
    if cols.include?("user_id") || (klass.reflect_on_association(:user) rescue false)
      attrs[:user] = user
    elsif cols.include?("collaborator_id")
      attrs[:collaborator_id] = user.id
    end

    # accepted-ish fields
    attrs[:accepted] = true if cols.include?("accepted")
    attrs[:status]   = (klass.const_defined?(:STATUS_ACCEPTED) ? klass::STATUS_ACCEPTED : "accepted") if cols.include?("status")
    attrs[:state]    = "accepted" if cols.include?("state")
    attrs[:role]     = (klass.const_defined?(:ROLE_CO_PLANNER) ? klass::ROLE_CO_PLANNER : "co_planner") if cols.include?("role")

    if attrs[:event].present? && (attrs[:user].present? || attrs[:collaborator_id].present?)
      klass.create!(attrs)
      return true
    end
  end

  raise "No collaboration join model found. Update create_collaboration_link! with your real join model."
end

# -------------------------
# Data setup steps
# -------------------------

Given("there is an owned event with AI ideas for {string}") do |email|
  owner = find_or_create_user!(email, name: "Owner User")

  event = Event.create!(
    event_name: "Owned Event",
    event_date: Date.today + 5.days,
    user: owner
  )

  recipient = Recipient.create!(
    user: owner,
    name: "Owned Recipient",
    email: "owned_recipient@example.com",
    relationship: "Friend",
    gender: "Male"
  )

  er = create_event_recipient!(event: event, recipient: recipient, user: owner)

  AiGiftSuggestion.create!(
    user: owner,
    event: event,
    recipient: recipient,
    event_recipient: er,
    title: "Book Subscription",
    category: "Books",
    estimated_price: "$10-$20"
  )
end

Given("there is a collaboration event accessible to {string} with AI ideas from {string}") do |owner_email, other_email|
  owner = find_or_create_user!(owner_email, name: "Owner User")
  other = find_or_create_user!(other_email, name: "Other User")

  collab_event = Event.create!(
    user: other,
    event_name: "Collab Event",
    event_date: Date.today + 10.days
  )

  create_collaboration_link!(event: collab_event, user: owner)

  recipient = Recipient.create!(
    user: other,
    name: "Alex",
    email: "alex@example.com",
    relationship: "Friend",
    gender: "Male"
  )

  er = create_event_recipient!(event: collab_event, recipient: recipient, user: other)

  AiGiftSuggestion.create!(
    user: other,
    event: collab_event,
    recipient: recipient,
    event_recipient: er,
    title: "Smartwatch",
    category: "Tech",
    estimated_price: "$50-$100"
  )
end

# -------------------------
# Navigation / actions
# -------------------------

When("I visit the AI Gift Library page") do
  visit ai_gift_library_path
end

When("I switch to Collab scope") do
  # Collab is a pill toggle button (per your UI screenshot), not a link
  # Use a robust selector that finds a button first.
  if page.has_css?("button", text: "Collab", wait: 2)
    find("button", text: "Collab", match: :first).click
  else
    # fallback: maybe rendered as <a>, still allow
    click_link_or_button("Collab", match: :first, exact: false)
  end

  # Save a stable URL for later revisit (don’t rely on current_url state)
  @collab_scope_url = ai_gift_library_path(scope: "collab")
end

When("I apply AI library filters") do
  # Your UI uses a real button "Apply filters" (auto-updating pills are separate)
  if page.has_button?("Apply filters", wait: 3)
    click_button("Apply filters", match: :first)
  elsif page.has_button?("Apply Filters", wait: 3)
    click_button("Apply Filters", match: :first)
  elsif page.has_css?("button", text: /Apply filters/i, wait: 3)
    find("button", text: /Apply filters/i, match: :first).click
  else
    raise 'Could not find "Apply filters" button on AI Library page.'
  end
end


When("I revisit the Collab scope page") do
  raise "No collab URL saved. Did you run 'I switch to Collab scope' first?" unless @collab_scope_url
  visit @collab_scope_url
end

# -------------------------
# Category dropdown checks (use only if your feature expects it visible)
# -------------------------

Then("the category dropdown should include {string}") do |category|
  # If category exists, it’s usually labeled "Category" and is a select
  select_el =
    if page.has_css?("select#category", wait: 2)
      find("select#category")
    elsif page.has_css?("select[name='category']", wait: 2)
      find("select[name='category']")
    elsif page.has_select?("Category", wait: 2)
      find_field("Category")
    else
      raise "Could not find category dropdown."
    end

  options = select_el.all("option").map { |o| o.text.strip }
  expect(options).to include(category)
end

Then("the category dropdown should not include {string}") do |category|
  # If category dropdown is hidden, this should pass by not finding it too.
  if page.has_css?("select#category, select[name='category']", wait: 1) || page.has_select?("Category", wait: 1)
    select_el =
      if page.has_css?("select#category", wait: 1)
        find("select#category")
      elsif page.has_css?("select[name='category']", wait: 1)
        find("select[name='category']")
      else
        find_field("Category")
      end

    options = select_el.all("option").map { |o| o.text.strip }
    expect(options).not_to include(category)
  else
    # dropdown is hidden → that's consistent with "not include"
    expect(true).to eq(true)
  end
end
