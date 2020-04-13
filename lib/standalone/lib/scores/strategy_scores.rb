class StrategyScores

    def initialize(strategy)
        @strategy = strategy
        ErrorHandling.abort_with_error_message(
            "unknown_strategy", "StrategyScores"
        ) unless is_known_strategy
        ErrorHandling.abort_with_error_message(
            "missing_strategy_matrix", "StrategyScores"
        ) unless is_strategy_data_defined
    end

    def is_strategy_to_select_for_original_codon
        @strategy == "raw"
    end

    def is_strategy_to_select_for_pessimal_codon
        @strategy == "attenuate"
    end

    def has_first_site_that_must_be_left_alone(last_codon, codon)
        # test codon is the second codon of a cross-codon CpG/ TpA pair
        last_codon = "" unless last_codon # HOTFIX if codon is starting ATG
        @strategy == "attenuate" &&
            (_generates_cross_neighbours_CpG?(last_codon, codon) || _generates_cross_neighbours_TpA?(last_codon, codon))
    end

    def normalised_scores(synonymous_codons, original_codon, next_codon, pos, is_near_intron, dist_to_intron)
        counts = synonymous_codons.collect do |synonymous_codon|
            codon_count(synonymous_codon, original_codon, next_codon, pos, is_near_intron, dist_to_intron)
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def is_known_strategy
        ["raw", "humanize", "gc", "max-gc", "attenuate"].include?(@strategy)
    end

    def is_strategy_data_defined
        case @strategy
        when "raw" then true
        when "humanize" then defined?(Human_codon_counts)
        when "gc", "attenuate"
            defined?(Third_site_frequencies) &&
            defined?(Third_site_counts_near_intron)
        when "max-gc" then defined?(Maximal_gc3)
        end
    end

    def codon_count(synonymous_codon, original_codon, next_codon, pos, is_near_intron, dist_to_intron)
        case @strategy
        when "raw"
            raw_count(synonymous_codon, original_codon)
        when "humanize"
            humanize_count(synonymous_codon)
        when "gc"
            gc_count(synonymous_codon, pos, is_near_intron, dist_to_intron)
        when "max-gc"
            max_gc_count(synonymous_codon)
        when "attenuate"
            attenuate_count(synonymous_codon, next_codon, pos, is_near_intron, dist_to_intron)
        end
    end

    def raw_count(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def humanize_count(synonymous_codon)
        Human_codon_counts[synonymous_codon]
    end

    def gc_count(synonymous_codon, pos, is_near_intron, dist)
        # NOTE pos is a nucleotide pos whereas Third_site_counts is in amino acid positions
        if is_near_intron
            # treat pos as distance to intron
            aa_dist = dist/3
            Third_site_counts_near_intron[synonymous_codon][aa_dist]
        else
            aa_pos = pos/3
            Third_site_frequencies[synonymous_codon].(aa_pos)
        end
    end

    def max_gc_count(synonymous_codon)
        Maximal_gc3[synonymous_codon]
    end

    def attenuate_count(synonymous_codon, next_codon, pos, is_near_intron, dist_to_intron)
        next_codon = "" unless next_codon # HOTFIX if codon is very last
        if _generates_CpG?(synonymous_codon, next_codon)
            addend = synonymous_codon.count("AT")/3.to_f
            1 + addend
        elsif _generates_TpA?(synonymous_codon, next_codon)
            addend = synonymous_codon.count("AT")/3.to_f
            # tweak addend to ensure CpGs still rank higher
            0.99 + addend*(1-0.99)
        else
            # score by usage in human genes while avoiding C's and G's
            multiplier = 1 - synonymous_codon.count("GC")/3.to_f
            (1 - gc_count(
                synonymous_codon, pos, is_near_intron, dist_to_intron)
            )*multiplier
        end
    end

    def _generates_CpG?(synonymous_codon, next_codon)
        _generates_cross_neighbours_CpG?(synonymous_codon, next_codon) || _generates_interal_CpG?(synonymous_codon)
    end

    def _generates_TpA?(synonymous_codon, next_codon)
        _generates_cross_neighbours_TpA?(synonymous_codon, next_codon) || _generates_interal_TpA?(synonymous_codon)
    end

    def _generates_cross_neighbours_CpG?(synonymous_codon, next_codon)
        synonymous_codon.end_with?("C") && next_codon.start_with?("G")
    end

    def _generates_interal_CpG?(synonymous_codon)
        # might be 1st/2nd site CpG or 2nd/3rd site CpG
        synonymous_codon.include?("CG")
    end

    def _generates_cross_neighbours_TpA?(synonymous_codon, next_codon)
        synonymous_codon.end_with?("T") && next_codon.start_with?("A")
    end

    def _generates_interal_TpA?(synonymous_codon)
        # might be 1st/2nd site CpG or 2nd/3rd site CpG
        synonymous_codon.include?("TA")
    end
end