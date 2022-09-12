FactoryBot.define do
  factory :vermillion_task, class: 'Vermillion::Task' do
    name { "vermillion/test" }
    description { { url: "test.mp4" } }

    trait :running do
      progress { 5 }
      total { 10 }
      started_at { 20.minutes.ago }
    end

    trait :failed do
      progress { 8 }
      total { 10 }
      started_at { 20.minutes.ago }
      completed_at { 10.minutes.ago }
      failed { true }
    end

    trait :completed do
      progress { 10 }
      total { 10 }
      started_at { 20.minutes.ago }
      completed_at { 10.minutes.ago }
    end

    trait :expired do
      progress { 10 }
      total { 10 }
      started_at { (10.days + 20.minutes).ago }
      completed_at { 10.days.ago }
    end
  end
end
