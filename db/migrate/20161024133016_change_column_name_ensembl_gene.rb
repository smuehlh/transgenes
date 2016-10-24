class ChangeColumnNameEnsemblGene < ActiveRecord::Migration
  def change
    rename_column :ensembl_genes, :sequence, :cds
  end
end
