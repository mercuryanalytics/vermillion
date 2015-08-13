json.task do
  json.status @task.status
  json.description @task.description
  json.expired_at @task.expired_at.iso8601 if @task.expired_at
  case @task.status
  when :running
    json.started_at @task.started_at.iso8601
    json.progress @task.progress
    json.total @task.total
  when :completed, :failed
    json.started_at @task.started_at.iso8601
    json.completed_at @task.completed_at.iso8601
    json.progress @task.progress
    json.total @task.total
  end
end
