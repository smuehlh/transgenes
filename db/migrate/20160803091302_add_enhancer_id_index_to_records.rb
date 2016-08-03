class AddEnhancerIdIndexToRecords < ActiveRecord::Migration
  def change
    add_index :records, :enhancer_id
  end
end
