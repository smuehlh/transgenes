class GeneEnhancer

    def initialize(strategy, select_best_by, stay_in_subbox_for_6folds)
        @n_variants = 1000

        @strategy = strategy
        @select_best_by = select_best_by
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @enhanced_genes = []
        @gc3_contents = [] # per gene
        @cross_variant_gc3_per_pos = []
    end

    def generate_synonymous_genes(gene)
        @n_variants.times do |num|
            @variant_number = Counting.ruby_to_human(num)
            variant, gc3, gc3_per_pos = generate_synonymous_variant(gene)

            @enhanced_genes.push variant
            @gc3_contents.push gc3
            update_cross_variant_gc3(gc3_per_pos)
        end
        log_cross_variant_gc3
    end

    def select_best_gene
        ind_best_gene = find_index_of_best_gene
        log_selection(ind_best_gene)

        @enhanced_genes[ind_best_gene]
    end

    private

    def mean_gc3
        if is_one_exon_genes
            # aim for the average gc3-content of 1-exon genes
            0.6058148688792696
        else
            # aim for the average gc3-content of 2-exon genes
            0.6175028566428371
        end
    end

    def generate_synonymous_variant(gene)
        copy = Marshal.load(Marshal.dump(gene))
        copy.tweak_sequence(@strategy, @stay_in_subbox_for_6folds)
        overall_gc3 = copy.gc3_content
        gc3_per_pos = copy.gc3_content_at_synonymous_sites
        log_generated_variant(copy, overall_gc3)

        [copy, overall_gc3, gc3_per_pos]
    end

    def update_cross_variant_gc3(gc3_per_pos)
        gc3_per_pos.each_with_index do |val, ind|
            @cross_variant_gc3_per_pos[ind] = 0 unless @cross_variant_gc3_per_pos[ind]
            @cross_variant_gc3_per_pos[ind] += val/@n_variants.to_f
        end
    end

    def log_generated_variant(gene, gc3)
        gc3 = to_pct(gc3)
        n_mutated_sites, mutated_sites = gene.log_changed_sites
        desc = "Variant #{@variant_number}: #{gc3}% GC3, #{n_mutated_sites} changed sites"

        $logger.info GeneToFasta.new(desc, gene.sequence).fasta
        $logger.debug mutated_sites
    end

    def log_cross_variant_gc3
        $logger.debug "GC3 per position, across all variants:"
        $logger.debug @cross_variant_gc3_per_pos.collect{|num| to_pct(num)}.join("\t")
    end

    def log_selection(variant_ind)
        variant_number = Counting.ruby_to_human(variant_ind)
        selected = to_pct(@gc3_contents[variant_ind])
        $logger.info "Target GC3 content: #{target_description}"
        $logger.info "Closest match: Variant #{variant_number} (#{selected}%)"
    end

    def find_index_of_best_gene
        case @select_best_by
        when "mean"
            distances_to_mean = @gc3_contents.collect{|gc| (gc - mean_gc3).abs}
            distances_to_mean.index(distances_to_mean.min)
        when "high"
            @gc3_contents.index(@gc3_contents.max)
        when "low"
            @gc3_contents.index(@gc3_contents.min)
        end
    end

    def target_description
        case @select_best_by
        when "mean"
            n_exons = is_one_exon_genes ? "1-exon" : "2-exon"
            "mean GC3 of #{n_exons} genes (#{to_pct(mean_gc3)}%)"
        when "high"
            "highest"
        when "low"
            "lowest"
        end
    end

    def to_pct(num)
        (num*100).round(2)
    end

    def is_one_exon_genes
        @enhanced_genes.first.introns.size == 0
    end
end