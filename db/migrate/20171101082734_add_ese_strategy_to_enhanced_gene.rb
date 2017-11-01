class AddEseStrategyToEnhancedGene < ActiveRecord::Migration
  def change
    add_column :enhanced_genes, :ese_strategy, :string
  end
end
