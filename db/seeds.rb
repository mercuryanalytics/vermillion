ActiveRecord::Base.transaction do
  # new task
  Vermillion::Task.create! description: { url: 'test.mp4' }
  # running task
  Vermillion::Task.create! description: { url: 'test.mp4' }, progress: 5, total: 10, started_at: 20.minutes.ago
  # failed task
  Vermillion::Task.create! description: { url: 'test.mp4' }, progress: 8, total: 10, started_at: 20.minutes.ago, completed_at: 10.minutes.ago, failed: true
  # completed task
  Vermillion::Task.create! description: { url: 'test.mp4' }, progress: 10, total: 10, started_at: 20.minutes.ago, completed_at: 10.minutes.ago
  # expired task
  Vermillion::Task.create! description: { url: 'test.mp4' }, progress: 10, total: 10, started_at: (10.days + 20.minutes).ago, completed_at: 10.days.ago
end
