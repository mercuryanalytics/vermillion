require 'rails_helper'

module Vermillion
  RSpec.describe Task, type: :model do

    it "validates description is present" do
      expect(:description).to be_present
    end

    it "can tell whether the task is expired" do
      expect(build(:vermillion_task, :expired)).to be_expired
    end

    context "life cycle" do
      it "is initially pending" do
        task = create(:vermillion_task)
        expect(task.status).to be :pending
      end

      it "updates the status when the task is started" do
        task = create(:vermillion_task)
        task.start!(100)
        expect(task.status).to be :running
        expect(task.started_at).to_not be_nil
        expect(task.progress).to eq 0
        expect(task.total).to eq 100
      end

      it "updates progress information when work is reported" do
        task = create(:vermillion_task, :running)
        expect(task.progress).to eq 5
        expect(task.total).to eq 10
        expect {
          task.increment_progress
        }.to change(task, :progress).by 1
        expect {
          task.increment_progress(4)
        }.to change(task, :progress).by 4
        expect(task.progress).to eq 10
        expect(task.status).to be :running
      end

      it "updates the status when the task is finished" do
        task = create(:vermillion_task, :running)
        task.finish!
        expect(task.progress).to eq task.total
        expect(task.completed_at).to_not be_nil
      end

      it "updates the status when the task is failed" do
        task = create(:vermillion_task, :running)
        task.fail!
        expect(task.completed_at).to_not be_nil
        expect(task.failed?).to be true
      end
    end

    it "can construct the corresponding ActiveJob instance" do
      task = create(:vermillion_task)
      expect(task.job.ancestors).to include(::ActiveJob::Base)
    end

    class SampleJob < ActiveJob::Base
    end

    it "validates the description against the job's schema" do
      task = build(:vermillion_task, name: "vermillion/sample", description: { property: "invalid description" })
      expect(task).to be_valid
    end
  end
end
