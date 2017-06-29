class GeneEnhancer

    attr_reader :cross_variant_gc3_per_pos, :fasta_formatted_gene_variants

    def initialize(strategy, select_best_by, stay_in_subbox_for_6folds)
        @n_variants = 1000

        @strategy = strategy
        @select_best_by = select_best_by
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @gene_variants = []
        @gc3_contents = [] # needed to select best variant
        @gc3_counts_per_pos = [] # needed to calc cross-variant GC3 per pos

        @cross_variant_gc3_per_pos = []
        @fasta_formatted_gene_variants = []
    end

    def generate_synonymous_genes(gene)
        gene.prepare_for_tweaking(@stay_in_subbox_for_6folds)

        @n_variants.times do |ind|
            variant = generate_variant(gene)
            log_variant(variant, ind)
            collect_variant_data(variant, ind)
        end
        convert_individual_to_cross_variant_gc3
        log_cross_variant_gc3

    rescue StandardError => exp
        # something went very wrong.
        ErrorHandling.abort_with_error_message(
            "variant_generation_error", "GeneEnhancer"
        )
    end

    def select_best_gene
        ind_best_gene = find_index_of_best_gene
        log_selection(ind_best_gene)

        @gene_variants[ind_best_gene]

    rescue StandardError => exp
        # something went very wrong.
        ErrorHandling.abort_with_error_message(
            "variant_selection_error", "GeneEnhancer"
        )
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

    def generate_variant(gene)
        gene.tweak_exonic_sequence(@strategy)
        gene.deep_copy_using_tweaked_sequence
    end

    def log_variant(variant, variant_ind)
        _, mutated_sites = variant.log_changed_sites
        fasta = convert_variant_to_fasta(variant, variant_ind)
        log_variant_sequence(fasta, mutated_sites)
    end

    def collect_variant_data(variant, variant_ind)
        fasta = convert_variant_to_fasta(variant, variant_ind)

        @gene_variants.push variant
        @gc3_contents.push variant.gc3_content
        @gc3_counts_per_pos.push variant.gc3_count_per_synonymous_site
        @fasta_formatted_gene_variants.push fasta
    end

    def convert_individual_to_cross_variant_gc3
        @gc3_counts_per_pos.transpose.each do |gc3s|
            gc3_content = Statistics.sum(gc3s) / @n_variants.to_f * 100
            @cross_variant_gc3_per_pos.push gc3_content
        end
    end

    def convert_variant_to_fasta(variant, variant_ind)
        variant_number = Counting.ruby_to_human(variant_ind)

        gc3 = to_pct(variant.gc3_content)
        ese_content = to_pct(variant.sequence_proportion_covered_by_eses)
        n_mutated_sites,_ = variant.log_changed_sites
        desc = "Variant #{variant_number}: #{gc3}% GC3, #{n_mutated_sites} changed sites, #{ese_content}% of sequence covered by ESEs"
        GeneToFasta.new(desc, variant.sequence).fasta
    end

    def log_variant_sequence(fasta, mutated_sites)
        $logger.info fasta
        $logger.debug mutated_sites
    end

    def log_cross_variant_gc3
        $logger.debug "GC3 per position, across all variants:"
        $logger.debug @cross_variant_gc3_per_pos.map{|n| n.round(2)}.join("\t")
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
        @gene_variants.first.introns.size == 0
    end
end