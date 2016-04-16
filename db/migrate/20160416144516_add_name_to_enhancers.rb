class AddNameToEnhancers < ActiveRecord::Migration
  def change
    add_column :enhancers, :name, :text
  end
end
