require 'rails_helper'

module Vermillion
  RSpec.describe Task, type: :model do
    context "factories" do
      it "can create new tasks" do
        task = build(:vermillion_task)
        expect(task).to be_valid
        expect(task.status).to be :new
      end

      it "can create running tasks" do
        task = build(:running_vermillion_task)
        expect(task).to be_valid
        expect(task.status).to be :running
        expect(task.total).to_not be_nil
        expect(task.progress).to_not be_nil
        expect(task.progress).to be < task.total
        expect(task.started_at).to_not be_nil
      end

      it "can create completed tasks" do
        task = build(:completed_vermillion_task)
        expect(task).to be_valid
        expect(task.status).to be :completed
        expect(task.progress).to eq task.total
        expect(task.completed_at).to_not be_nil
      end

      it "can create failed tasks" do
        task = build(:failed_vermillion_task)
        expect(task).to be_valid
        expect(task.status).to be :failed
        expect(task.failed?).to be true
        expect(task.completed_at).to_not be_nil
      end

      it "can create expired tasks" do
        task = build(:expired_vermillion_task)
        expect(task).to be_valid
        expect(task.status).to be :expired
      end
    end

    it "is invalid without a definition" do
      expect(build(:vermillion_task, definition: nil)).not_to be_valid
    end

    it "can tell whether the task is expired" do
      expect(build(:vermillion_task, progress: 10, total: 10, started_at: (10.days + 20.minutes).ago, completed_at: 10.days.ago)).to be_expired
    end

    context "life cycle" do
      it "updates the status when the task is started" do
        task = create(:vermillion_task)
        task.start!(100)
        expect(task.status).to be :running
        expect(task.started_at).to_not be_nil
        expect(task.progress).to eq 0
        expect(task.total).to eq 100
      end

      it "updates progress information when work is reported" do
        task = create(:running_vermillion_task)
        expect(task.progress).to eq 5
        expect(task.total).to eq 10
        expect {
          task.update_progress
        }.to change(task, :progress).by 1
        expect {
          task.update_progress(4)
        }.to change(task, :progress).by 4
        expect(task.progress).to eq 10
        expect(task.status).to be :running
      end

      it "updates the status when the task is finished" do
        task = create(:running_vermillion_task)
        task.finish!
        expect(task.progress).to eq task.total
        expect(task.completed_at).to_not be_nil
      end

      it "updates the status when the task is failed" do
        task = create(:running_vermillion_task)
        task.fail!
        expect(task.completed_at).to_not be_nil
        expect(task.failed?).to be true
      end
    end
  end
end
