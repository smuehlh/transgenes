class AddGenenameToEnhancer < ActiveRecord::Migration
  def change
    add_column :enhancers, :gene_name, :text
  end
end
