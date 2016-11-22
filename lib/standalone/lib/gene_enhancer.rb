class GeneEnhancer

    def initialize(strategy, stay_in_subbox_for_6folds)
        @strategy = strategy
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @enhanced_genes = []
    end

    def generate_synonymous_genes(gene)
        @enhanced_genes = 1000.times.collect do
            generate_synonymous_variant(gene)
        end
    end

    def select_best_gene
        @enhanced_genes.first
    end

    private

    def generate_synonymous_variant(gene)
        copy = Marshal.load(Marshal.dump(gene))
        copy.tweak_sequence(@strategy, @stay_in_subbox_for_6folds)
        copy.log_tweak_statistics
        copy
    end
end
