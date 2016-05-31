class AddExonsIntronsToEnhancer < ActiveRecord::Migration
  def change
    add_column :enhancers, :exons, :text, array:true, default: []
    add_column :enhancers, :introns, :text, array:true, default: []
  end
end
