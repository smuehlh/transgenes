class CreateEnhancedGenes < ActiveRecord::Migration
  def change
    create_table :enhanced_genes do |t|
      t.text :gene_name
      t.text :data
      t.text :log
      t.string :strategy
      t.boolean :keep_first_intron

      t.timestamps null: false
    end
  end
end
