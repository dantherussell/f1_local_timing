class CreateDays < ActiveRecord::Migration[8.1]
  def change
    create_table :days do |t|
      t.date :date, null: false
      t.string :local_time_offset
      t.references :weekend, null: false, foreign_key: true

      t.timestamps
    end

    add_index :days, [ :weekend_id, :date ], unique: true
  end
end
