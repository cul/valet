module ApplicationHelper

  def application_uptime
    time_ago_in_words(BOOTED_AT)
  end

end
