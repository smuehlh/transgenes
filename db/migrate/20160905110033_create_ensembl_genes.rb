class CreateEnsemblGenes < ActiveRecord::Migration
  def change
    create_table :ensembl_genes do |t|
      t.text :sequence
      t.string :gene_id
      t.string :version

      t.timestamps null: false
    end
  end
end
