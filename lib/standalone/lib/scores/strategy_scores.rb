class StrategyScores

    def initialize(strategy, cpg_enrichment_score=nil)
        @strategy = strategy
        @cpg_enrichment_score = cpg_enrichment_score # only needed for attenuate strategy
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

    def is_strategy_calling_for_shuffled_synonymous_codons_list
        # explanation: otherwise, codons with same score are selected deterministically
        @strategy == "attenuate"
    end

    def is_strategy_dictating_first_site_to_be_A(previous_codon, synonymous_codons)
        # check if previous_codon has been selected to add a cross-codon TpA
        # with one of the synonymous codons
        # this is only relevant for 6-folds and only for TpA (as no 6-fold )
        # (no 6-fold codon starts with G)
        previous_codon = "" unless previous_codon # HOTFIX if codon is starting ATG
        @strategy == "attenuate" &&
            synonymous_codons.size == 6 &&
            previous_codon.end_with?("T") && at_least_one_synonymous_codon_starts_with_A(synonymous_codons)
    end

    def normalised_scores(synonymous_codons, original_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        counts = synonymous_codons.collect do |synonymous_codon|
            codon_count(synonymous_codon, original_codon, synonymous_codons, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        end
        counts = Statistics.shift_into_positive_range_if_negative(counts)
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def is_known_strategy
        ["raw", "humanize", "gc", "max-gc", "attenuate"].
            include?(@strategy)
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

    def codon_count(synonymous_codon, original_codon, synonymous_codons, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
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
            attenuate_count(synonymous_codon, synonymous_codons, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
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

    def attenuate_count(codon, codon_synonyms, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        # NOTE:
        # if / elsif means that order of checks determines score
        # however, there is not better solution as scores can't be added either (due to potentially negative score)
        scores = []
        if yields_most_CpG(codon, codon_synonyms, next_codon_synonyms)
            scores.push 2 / @cpg_enrichment_score.to_f
        end
        if yields_most_T(codon, codon_synonyms)
            scores.push 2 / @cpg_enrichment_score.to_f
        end
        if yields_most_TpA(codon, codon_synonyms, next_codon_synonyms)
            scores.push 1 / @cpg_enrichment_score.to_f
        end
        if yields_most_A(codon, codon_synonyms)
            scores.push 1 / @cpg_enrichment_score.to_f
        end
        if scores.any?
            scores.max
        else
            # inverse usage in human genes
            inverted_human_score(codon, pos, is_near_intron, dist_to_intron)
        end
    end

    def yields_most_CpG(codon, codon_synonyms, next_codon_synonyms)
        first_site_next_codon =
            if next_codon_synonyms
                # in all codon boxes, either all codons start with G or none does
                next_codon_synonyms[0][0]
            else
                # HOTFIX if codon is last codon
                ""
            end
        max_CpG = codon_synonyms.collect do |c|
            (c + first_site_next_codon).scan("CG").size
        end.max

        (codon + first_site_next_codon).include?("CG") &&
            (codon + first_site_next_codon).scan("CG").size == max_CpG
    end

    def yields_most_TpA(codon, codon_synonyms, next_codon_synonyms)
        # set to A if some codons of box start with A, else set to ""
        first_site_next_codon =
            if at_least_one_synonymous_codon_starts_with_A(next_codon_synonyms)
                "A"
            else
                ""
            end
        max_TpA = codon_synonyms.collect do |c|
            (c + first_site_next_codon).scan("TA").size
        end.max
        (codon + first_site_next_codon).include?("TA") &&
            (codon + first_site_next_codon).scan("TA").size == max_TpA
    end

    def yields_most_T(codon, codon_synonyms)
        max_T = codon_synonyms.collect{|c| c.count("T")}.max
        codon.include?("T") && codon.count("T") == max_T
    end

    def yields_most_A(codon, codon_synonyms)
        max_A = codon_synonyms.collect{|c| c.count("A")}.max
        codon.include?("A") && codon.count("A") == max_A
    end

    def inverted_human_score(synonymous_codon, pos, is_near_intron, dist_to_intron)
        score = 1 - gc_count(synonymous_codon, pos, is_near_intron, dist_to_intron)
        if score.infinite?
            # fix non-existing scores
            0
        else
            score
        end
    end

    def at_least_one_synonymous_codon_starts_with_A(synonymous_codons)
        synonymous_codons && synonymous_codons.any?{|c| c.start_with?("A")}
    end
end