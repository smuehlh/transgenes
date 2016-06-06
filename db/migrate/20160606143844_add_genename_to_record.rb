class AddGenenameToRecord < ActiveRecord::Migration
  def change
    add_column :records, :gene_name, :text
  end
end
