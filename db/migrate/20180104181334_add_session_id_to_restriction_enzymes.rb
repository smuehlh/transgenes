class AddSessionIdToRestrictionEnzymes < ActiveRecord::Migration
  def change
    add_column :restriction_enzymes, :session_id, :string
  end
end
