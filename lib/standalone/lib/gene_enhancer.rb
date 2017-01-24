class GeneEnhancer

    def initialize(strategy, stay_in_subbox_for_6folds)
        @strategy = strategy
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @enhanced_genes = []
        @gc3_contents = []
    end

    def generate_synonymous_genes(gene)
        1000.times do |num|
            @variant_number = Counting.ruby_to_human(num)
            gene, gc3 = generate_synonymous_variant(gene)

            @enhanced_genes.push gene
            @gc3_contents.push gc3
        end
    end

    def select_best_gene
        distances_to_target = @gc3_contents.collect{|gc| (gc - target_gc_content).abs}
        ind_best_gene = distances_to_target.index(distances_to_target.min)
        log_selection(ind_best_gene)

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
        gc3 = gene.gc3_content
        log_generated_variant(copy, gc3)

        [copy, gc3]
    end

    def log_generated_variant(gene, gc3)
        gc3 = to_pct(gc3)
        n_mutated_sites, mutated_sites = gene.log_changed_sites
        desc = "Variant #{@variant_number}: #{gc3}% GC3, #{n_mutated_sites} changed sites"

        $logger.info GeneToFasta.new(desc, gene.sequence).fasta
        $logger.debug mutated_sites
    end

    def log_selection(variant_ind)
        variant_number = Counting.ruby_to_human(variant_ind)
        target = to_pct(target_gc_content)
        selected = to_pct(@gc3_contents[variant_ind])
        $logger.info "Target GC3 content: #{target}%"
        $logger.info "Closest match: Variant #{variant_number} (#{selected})%"
    end

    def to_pct(num)
        (num*100).round(2)
    end
end