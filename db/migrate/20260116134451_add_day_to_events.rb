class AddDayToEvents < ActiveRecord::Migration[8.1]
  def change
    # Add day reference (nullable at first for migration)
    add_reference :events, :day, foreign_key: true

    # Change start_time from datetime to time
    change_column :events, :start_time, :time

    # Remove weekend reference
    remove_reference :events, :weekend, foreign_key: true

    # Make day_id not null after migration
    change_column_null :events, :day_id, false
  end
end
