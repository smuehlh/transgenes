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
        gc_contents = @enhanced_genes.collect{|gene| gene.gc_content}
        distances_to_target = gc_contents.collect{|gc| (gc - target_gc_content).abs}
        ind_best_gene = distances_to_target.index(distances_to_target.min)

        @enhanced_genes[ind_best_gene]
    end

    private

    def target_gc_content
        if @enhanced_genes.first.introns == 0
            # aim for the overall gc-content of 1-exon genes
            0.526380034851897
        else
            # aim for the gc-content of 2-exon genes
            0.5464775145490496
        end
    end

    def generate_synonymous_variant(gene)
        copy = Marshal.load(Marshal.dump(gene))
        copy.tweak_sequence(@strategy, @stay_in_subbox_for_6folds)
        copy.log_tweak_statistics
        copy
    end
end
