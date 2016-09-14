class AddGeneIdIndexToEnsemblGenes < ActiveRecord::Migration
  def change
    add_index :ensembl_genes, :gene_id
  end
end
