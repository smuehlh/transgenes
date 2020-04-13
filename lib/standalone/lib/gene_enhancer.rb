class GeneEnhancer
    attr_reader :cross_variant_gc3_per_pos, :fasta_formatted_gene_variants

    def initialize(options)
        @n_variants = options.greedy ? 1 : 1000
        @strategy = options.strategy
        @ese_strategy = options.ese_strategy
        @select_best_by = options.select_by
        @stay_in_subbox_for_6folds = options.stay_in_subbox_for_6folds
        @score_eses_at_all_sites = options.score_eses_at_all_sites

        @gene_variants = []
        @gc3_contents = [] # needed to select best variant
        @ese_resemblance = [] # need to select best variant (in case of a tie)
        @gc3_counts_per_pos = [] # needed to calc cross-variant GC3 per pos

        @cross_variant_gc3_per_pos = []
        @fasta_formatted_gene_variants = []
    end

    def generate_synonymous_genes(gene)
        gene.prepare_for_tweaking(@stay_in_subbox_for_6folds)

        @n_variants.times do |ind|
            variant = generate_variant(gene, ind)
            log_variant(variant)
            collect_variant_data(variant)
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
        if @n_variants == 1
            ind_best_gene = 0
        else
            ind_best_gene = find_index_of_best_gene
        end
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

    def generate_variant(gene, variant_ind)
        variant_number = Counting.ruby_to_human(variant_ind)

        # NOTE - 'attenuate' strategy and @greedy option go hand in hand
        # thus it is not neccessary to pass @greedy on to variant generation
        gene.tweak_exonic_sequence(@strategy, @ese_strategy, @score_eses_at_all_sites)
        gene.deep_copy_using_tweaked_sequence(variant_number)
    end

    def log_variant(variant)
        _, mutated_sites = variant.log_changed_sites
        fasta = convert_variant_to_fasta(variant)
        log_variant_sequence(fasta, mutated_sites)
    end

    def collect_variant_data(variant)
        @gene_variants.push variant
        @gc3_contents.push variant.gc3_content
        @ese_resemblance.push variant.sequence_proportion_covered_by_eses
        @gc3_counts_per_pos.push variant.gc3_count_per_synonymous_site
        @fasta_formatted_gene_variants.push convert_variant_to_fasta(variant)
    end

    def convert_individual_to_cross_variant_gc3
        @gc3_counts_per_pos.transpose.each do |gc3s|
            gc3_content = Statistics.sum(gc3s) / @n_variants.to_f * 100
            @cross_variant_gc3_per_pos.push gc3_content
        end
    end

    def convert_variant_to_fasta(variant)
        GeneToFasta.new(variant.description, variant.sequence).fasta
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
        gc3 = Statistics.percents(@gc3_contents[variant_ind])
        ese = Statistics.percents(@ese_resemblance[variant_ind])
        $logger.info "Target GC3 content: #{target_description}"
        $logger.info "Subsequent target: #{ese_target_description} ESE resemblance"
        $logger.info "Closest match: Variant #{variant_number} (#{gc3}% GC3; #{ese}% ESE resemblance)"

        $logger.info "Full statistics selected variant:\n"
        @gene_variants[variant_ind].log_statistics
        $logger.info ""
    end

    def find_index_of_best_gene
        # (mainly) select by GC3
        # in case of a tie: additional selection by ESE resemblance
        gc3_selection_target =
            case @select_best_by
            when "mean"
                distances_to_mean = @gc3_contents.collect{|gc3| (gc3 - mean_gc3).abs}
                distances_to_mean.min
            when "high"
                @gc3_contents.max
            when "low"
                @gc3_contents.min
            end
        best_by_gc3 =
            @gc3_contents.each_index.select do |ind|
                if @select_best_by == "mean"
                    # use distance rather than gc3 for selection
                    distances_to_mean[ind] == gc3_selection_target
                else
                    @gc3_contents[ind] == gc3_selection_target
                end

            end

        if @ese_strategy == "deplete"
            best_by_gc3.min_by{|i| @ese_resemblance[i]}
        else
            best_by_gc3.max_by{|i| @ese_resemblance[i]}
        end
    end

    def target_description
        case @select_best_by
        when "mean"
            n_exons = is_one_exon_genes ? "1-exon" : "2-exon"
            "mean GC3 of #{n_exons} genes (#{Statistics.percents(mean_gc3)}%)"
        when "high"
            "highest"
        when "low"
            "lowest"
        end
    end

    def ese_target_description
        if @ese_strategy == "deplete"
            "minimal"
        else
            "maximal"
        end
    end

    def is_one_exon_genes
        @gene_variants.first.introns.size == 0
    end
end