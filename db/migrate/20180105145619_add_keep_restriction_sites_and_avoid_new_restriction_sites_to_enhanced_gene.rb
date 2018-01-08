class AddKeepRestrictionSitesAndAvoidNewRestrictionSitesToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :keep_restriction_sites, :boolean
    add_column :enhanced_genes, :avoid_restriction_sites, :boolean
  end
end
