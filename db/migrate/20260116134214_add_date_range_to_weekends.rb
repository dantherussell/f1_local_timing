class AddDateRangeToWeekends < ActiveRecord::Migration[8.1]
  def change
    add_column :weekends, :first_day, :date
    add_column :weekends, :last_day, :date
    remove_column :weekends, :timespan, :string
  end
end
