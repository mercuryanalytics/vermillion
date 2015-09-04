namespace :vermillion do
  desc "Lists tasks"
  task :tasks => :environment do |t|
    puts "Status    ID                                   Started              Completed            Progress"
    Vermillion::Task.all.each do |task|
      case task.status
      when :running
        puts "running   #{task.id} #{task.started_at.iso8601}                      #{task.progress}/#{task.total}"
      when :completed
        puts "completed #{task.id} #{task.started_at.iso8601} #{task.completed_at.iso8601}"
      when :failed
        puts "failed    #{task.id} #{task.started_at.iso8601} #{task.completed_at.iso8601} #{task.progress}/#{task.total}"
      when :new
        puts "new       #{task.id}"
      when :expired
        puts "expired   #{task.id}"
      end
    end
  end

  def tasks_for(id, scope = :running_tasks)
    if id
      [Vermillion::Task.find(id)]
    else
      Vermillion::Task.send(scope)
    end
  end

  desc "Moves task to 'running'"
  task :start, [:id] => :environment do |t,params|
    tasks_for(params[:id], :pending_tasks).each {|task| task.start!(100) }
  end

  desc "Update progress"
  task :progress, [:id] => :environment do |t,params|
    tasks_for(params[:id]).each {|task| task.update_progress(25) }
  end

  desc "Moves task to 'completed'"
  task :complete, [:id] => :environment do |t,params|
    tasks_for(params[:id]).each {|task| task.finish! }
  end

  desc "Moves task to 'failed'"
  task :fail, [:id] => :environment do |t,params|
    tasks_for(params[:id]).each {|task| task.fail! }
  end

  desc "Delete expired tasks"
  task :clean => :environment do |t,params|
    Vermillion::Task.expired_tasks.destroy_all
  end
end
