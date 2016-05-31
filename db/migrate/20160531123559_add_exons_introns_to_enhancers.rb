class AddExonsIntronsToEnhancers < ActiveRecord::Migration
  def change
    add_column :enhancers, :exons, :text
    add_column :enhancers, :introns, :text
  end
end
