class AddGc3PerIndividualVariantToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :gc3_per_individual_variant, :text
  end
end