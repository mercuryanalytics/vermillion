class CreateVermillionTasks < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'

    create_table :vermillion_tasks, id: :uuid do |t|
      t.json :description, null: false
      t.integer :progress
      t.integer :total
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean :failed, null: false, default: false

      t.timestamps null: false
    end
  end
end
