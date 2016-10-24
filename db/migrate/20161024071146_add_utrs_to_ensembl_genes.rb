class AddUtrsToEnsemblGenes < ActiveRecord::Migration
  def change
    add_column :ensembl_genes, :utr5, :text
    add_column :ensembl_genes, :utr3, :text
  end
end
