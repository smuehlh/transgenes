class AddExonsIntronsToRecords < ActiveRecord::Migration
  def change
    add_column :records, :exons, :text
    add_column :records, :introns, :text
  end
end
