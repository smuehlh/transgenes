class GeneEnhancer

    def initialize(strategy, stay_in_subbox_for_6folds)
        @strategy = strategy
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @enhanced_genes = []
    end

    def generate_synonymous_genes(gene)
        copy = copy_gene(gene)

        copy.tweak_sequence(@strategy, @stay_in_subbox_for_6folds)
        copy.log_tweak_statistics
        @enhanced_genes.push copy
    end

    def select_best_gene
        @enhanced_genes.first
    end

    private

    def copy_gene(gene)
        Marshal.load(Marshal.dump(gene))
    end
end
