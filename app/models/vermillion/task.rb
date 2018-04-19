module Vermillion
  class Task < ActiveRecord::Base
    validates :description, presence: true

    validate :description_validates_against_job_schema
    def description_validates_against_job_schema
      unless name
        errors.add(:name, "is required")
        return
      end

      begin
        if job.respond_to? :description_schema
          JSON::Validator.fully_validate(job.description_schema, description).each do |message|
            errors.add(:description, message)
          end
        end
      rescue NameError
        errors[:name] << "is not a job name"
      end
    end

    EXPIRED_PREDICATE = "completed_at + INTERVAL '1 day' < current_timestamp".freeze
    scope :pending_tasks, -> { where(started_at: nil) }
    scope :expired_tasks, -> { where(EXPIRED_PREDICATE) }
    scope :live_tasks, -> { where.not(EXPIRED_PREDICATE) }
    scope :failed_tasks, -> { live_tasks.where(failed: true) }
    scope :completed_tasks, -> { live_tasks.where(failed: false) }
    scope :running_tasks, -> { where(completed_at: nil).where.not(started_at: nil) }

    def job
      @job ||= "#{name}_job".camelize.constantize
    end

    def perform_later(*args)
      job.perform_later(self, *args)
    end

    def status
      if expired?
        :expired
      elsif failed?
        :failed
      elsif completed_at?
        :completed
      elsif started_at?
        :running
      else
        :pending
      end
    end

    def expired?
      completed_at? && expired_at.past?
    end

    def expired_at
      if completed_at?
        1.day.since(completed_at)
      else
        1.day.since(updated_at)
      end
    end

    def start!(total)
      update(started_at: Time.now, total: total, progress: 0)
    end

    def update_progress(n)
      Rails.logger.silence do
        update!(progress: n)
      end
    end

    def increment_progress(n = 1)
      increment!(:progress, n)
    end

    def finish!(results = nil)
      description.merge!(results) unless results.nil?
      self.progress = total
      self.completed_at = Time.now
      save
    end

    def fail!(results = nil)
      description.merge!(results) unless results.nil?
      self.completed_at = Time.now
      self.failed = true
      save
    end
  end
end
