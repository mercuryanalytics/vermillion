module Vermillion
  class Task < ActiveRecord::Base
    validates :description, presence: true

    EXPIRED_PREDICATE = "completed_at + INTERVAL '1 day' < current_timestamp"
    scope :pending_tasks, -> { where(started_at: nil) }
    scope :expired_tasks, -> { where(EXPIRED_PREDICATE) }
    scope :ended_tasks, -> { where.not(EXPIRED_PREDICATE) }
    scope :failed_tasks, -> { ended_tasks.where(failed: true) }
    scope :completed_tasks, -> { ended_tasks.where(failed: false) }
    scope :running_tasks, -> { where(completed_at: nil).where.not(started_at: nil) }

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
        :pending
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
