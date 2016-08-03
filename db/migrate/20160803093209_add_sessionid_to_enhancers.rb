class AddSessionidToEnhancers < ActiveRecord::Migration
  def change
    add_column :enhancers, :session_id, :string
  end
end
