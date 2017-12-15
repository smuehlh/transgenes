class AddScoreEsesAtAllSitesToEnhancedGenes < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :score_eses_at_all_sites, :boolean
  end
end
