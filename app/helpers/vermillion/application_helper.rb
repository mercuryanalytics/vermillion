module Vermillion
  module ApplicationHelper
    def time_tag(t)
      content_tag :time, t, datetime: t.iso8601
    end
  end
end
