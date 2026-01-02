class CreateWeekends < ActiveRecord::Migration[8.0]
  def change
    create_table :weekends do |t|
      t.string :gp_title
      t.string :location
      t.string :timespan
      t.string :local_timezone
      t.string :local_time_offset
      t.integer :race_number
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
  end
end
