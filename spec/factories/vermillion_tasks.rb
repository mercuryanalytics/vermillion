FactoryGirl.define do
  factory :vermillion_task, class: 'Vermillion::Task' do
    definition(url: 'test.mp4')

    factory :running_vermillion_task, class: 'Vermillion::Task' do
      progress 5
      total 10
      started_at 20.minutes.ago
    end

    factory :failed_vermillion_task, class: 'Vermillion::Task' do
      progress 8
      total 10
      started_at 20.minutes.ago
      failed true
    end

    factory :completed_vermillion_task, class: 'Vermillion::Task' do
      progress 10
      total 10
      started_at 20.minutes.ago
      completed_at 10.minutes.ago
    end

    factory :expired_vermillion_task, class: 'Vermillion::Task' do
      progress 10
      total 10
      started_at (10.days + 20.minutes).ago
      completed_at 10.days.ago
    end
  end
end
