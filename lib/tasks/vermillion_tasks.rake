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

  desc "Moves task to 'running'"
  task :start, [:id] => :environment do |t,params|
    if params[:id]
      Vermillion::Task.find(params[:id]).start!(100)
    else
      Vermillion::Task.pending_tasks.each {|task| task.start!(100) }
    end
  end
end
