module Vermillion
  class Task < ActiveRecord::Base
    validates :definition, presence: true

    def status
      if self.expired?
        :expired
      elsif self.failed?
        :failed
      elsif self.completed_at?
        :completed
      elsif self.started_at?
        :running
      else
        :new
      end
    end

    def expired?
      self.completed_at? && self.expired_at.past?
    end

    def expired_at
      1.day.since(self.completed_at) if self.completed_at?
    end

    def start!(total)
      update(started_at: DateTime.now, total: total, progress: 0)
    end

    def update_progress(n = 1)
      increment(:progress, n)
    end

    def finish!
      update(progress: self.total, completed_at: DateTime.now)
    end

    def fail!
      update(completed_at: DateTime.now, failed: true)
    end
  end
end
=begin
      t.json :definition, null: false
      t.integer :progress
      t.integer :total
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean :failed, null: false, default: false
=end
