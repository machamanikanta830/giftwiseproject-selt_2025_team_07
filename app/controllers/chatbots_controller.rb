class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  # POST /chatbot/message
  def message
    session[:chatbot_history] ||= default_history

    command = params[:command].to_s
    intent  = params[:intent].to_s.presence
    text    = params[:text].to_s.strip

    case command
    when "reset"
      session[:chatbot_history] = default_history
      return render json: {
        messages: session[:chatbot_history],
        quick_replies: quick_replies(nil)
      }
    when "exit"
      session.delete(:chatbot_history)
      return render json: { messages: [], quick_replies: quick_replies(nil) }
    end

    # 1) Store user message (if any)
    if text.present?
      session[:chatbot_history] << { "role" => "user", "text" => text }
    end

    # 2) Generate bot reply (intent may be explicit or inferred from text)
    reply_text = generate_reply(intent, text)

    session[:chatbot_history] << { "role" => "bot", "text" => reply_text }

    render json: {
      messages: session[:chatbot_history],
      quick_replies: quick_replies(intent)
    }
  end

  private

  def default_history
    first_name = current_user.name.to_s.split.first || "there"
    [
      {
        "role" => "bot",
        "text" => "Hi #{first_name}! 👋\nI'm your GiftWise Assistant.\n\nYou can tap a suggestion like **“Upcoming events”** or ask simple questions about your events, recipients, and wishlist."
      }
    ]
  end

  # Return a human readable answer
  def generate_reply(intent, text)
    intent ||= infer_intent_from_text(text)

    case intent
    when "upcoming_events"
      upcoming_events_reply
    when "recipient_count"
      recipient_count_reply
    when "wishlist_summary"
      wishlist_summary_reply
    when "help_add_event"
      help_add_event_reply
    when "help_add_recipient"
      help_add_recipient_reply
    when "help_wishlist"
      help_wishlist_reply
    else
      generic_fallback_reply
    end
  end

  # Very simple keyword matching if user types free-form text
  def infer_intent_from_text(text)
    down = text.downcase

    return "upcoming_events"   if down.include?("upcoming") && down.include?("event")
    return "upcoming_events"   if down.include?("next event")
    return "recipient_count"   if down.include?("recipient")
    return "wishlist_summary"  if down.include?("wishlist")
    return "help_add_event"    if down.include?("add event") || down.include?("create event")
    return "help_add_recipient" if down.include?("add recipient") || down.include?("create recipient")
    return "help_wishlist"     if down.include?("help") && down.include?("wishlist")

    nil
  end

  # ---------- DB-backed replies ----------

  def upcoming_events_reply
    events = current_user
               .events
               .where("event_date >= ?", Date.today)
               .order(:event_date)
               .limit(5)

    if events.empty?
      "You don’t have any upcoming events yet.\n\nYou can create one by clicking **“+ Add Event”** on the dashboard."
    else
      lines = events.map do |e|
        date = e.event_date&.strftime("%b %d, %Y") || "no date"
        budget = e.budget.present? ? "$#{sprintf('%.2f', e.budget)}" : "no budget"
        loc = e.location.presence || "no location"
        "• **#{e.event_name}** – #{date}, #{loc}, #{budget}"
      end

      "Here are your next #{events.size} event(s):\n\n" + lines.join("\n")
    end
  end

  def recipient_count_reply
    count = current_user.recipients.count
    if count.zero?
      "You don’t have any recipients yet.\n\nClick the **Recipients** card on the dashboard, then **“New Recipient”** to add someone."
    else
      names = current_user.recipients.order(created_at: :desc).limit(5).pluck(:name)
      summary = "You currently have **#{count} recipient#{'s' if count != 1}** saved."

      if names.any?
        summary + "\n\nRecent recipients:\n" + names.map { |n| "• #{n}" }.join("\n")
      else
        summary
      end
    end
  end

  def wishlist_summary_reply
    wishlists = current_user.wishlists.includes(:recipient).order(created_at: :desc).limit(5)

    if wishlists.empty?
      "You don’t have any wishlist items yet.\n\nOpen **Wishlists** from the header to start adding ideas you don’t want to forget."
    else
      lines = wishlists.map do |w|
        rec_name = w.recipient&.name || "Someone"
        title = w.item_name.presence || "Unnamed item"
        prio = w.priority.present? ? " (priority #{w.priority})" : ""
        "• **#{title}** for _#{rec_name}_#{prio}"
      end

      "Here are some of your recent wishlist items:\n\n" + lines.join("\n")
    end
  end

  # ---------- Static help replies ----------

  def help_add_event_reply
    <<~TEXT.squish
      To add a new event:
      1) On the dashboard, click the **Events** card or “+ Add Event”.
      2) Fill in event name, date, location, and budget (optional).
      3) Save the event.
      4) After that you can attach recipients and use “Get Ideas” for AI gift suggestions.
    TEXT
  end

  def help_add_recipient_reply
    <<~TEXT.squish
      To add a new recipient:
      1) Click the **Recipients** card on the dashboard.
      2) Press **“New Recipient”**.
      3) Enter their name, email and other details.
      4) Save – they’ll be available to attach to any event.
    TEXT
  end

  def help_wishlist_reply
    <<~TEXT.squish
      To manage your wishlist:
      1) Click the heart icon in the header to open **Wishlists**.
      2) Add items you’d like to remember for each recipient.
      3) You can mark priority so the most important ideas stay on top.
    TEXT
  end

  def generic_fallback_reply
    "I can help with quick things like:\n" \
      "• Upcoming events\n" \
      "• How many recipients you have\n" \
      "• A short wishlist summary\n\n" \
      "Try tapping one of the suggestion buttons below 👇"
  end

  # Suggestions shown as clickable “chips”
  def quick_replies(_intent)
    [
      { label: "Upcoming events",      intent: "upcoming_events" },
      { label: "How many recipients?", intent: "recipient_count" },
      { label: "Wishlist summary",     intent: "wishlist_summary" },
      { label: "How do I add an event?",     intent: "help_add_event" },
      { label: "How do I add a recipient?",  intent: "help_add_recipient" },
      { label: "Help with wishlists",  intent: "help_wishlist" }
    ]
  end
end
