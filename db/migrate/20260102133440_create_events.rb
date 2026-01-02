class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :racing_class
      t.string :name
      t.datetime :start_time
      t.string :local_time_offset
      t.references :weekend, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
