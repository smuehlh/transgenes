class AddSessionIdIndexToEnhancers < ActiveRecord::Migration
  def change
    add_index :enhancers, :session_id
  end
end
