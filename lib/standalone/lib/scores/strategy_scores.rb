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
        @strategy.start_with?("attenuate")
    end

    def has_first_site_that_must_be_left_alone(last_codon, codon)
        # test codon is the second codon of a cross-codon CpG/ TpA pair
        last_codon = "" unless last_codon # HOTFIX if codon is starting ATG
        @strategy == "attenuate" &&
            (_generates_cross_neighbours_CpG?(last_codon, codon) || _generates_cross_neighbours_TpA?(last_codon, codon))
    end

    def normalised_scores(synonymous_codons, original_codon, next_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        counts = synonymous_codons.collect do |synonymous_codon|
            codon_count(synonymous_codon, original_codon, next_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    def pessimal_scores_for_codons_producing_tie(synonymous_codons, pos, is_near_intron, dist_to_intron)
        # exception for attenuate_count: multiple codons producing identical score
        # => re-score solely by usage in human genes
        counts = synonymous_codons.collect do |synonymous_codon|
            _pessimal_human_score(synonymous_codon, pos, is_near_intron, dist_to_intron)
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def is_known_strategy
        ["raw", "humanize", "gc", "max-gc",
            "attenuate", "attenuate-maxT"
        ].include?(@strategy)
    end

    def is_strategy_data_defined
        case @strategy
        when "raw" then true
        when "humanize" then defined?(Human_codon_counts)
        when "gc", "attenuate", "attenuate-maxT"
            defined?(Third_site_frequencies) &&
            defined?(Third_site_counts_near_intron)
        when "max-gc" then defined?(Maximal_gc3)
        end
    end

    def codon_count(synonymous_codon, original_codon, next_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
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
            attenuate_count(synonymous_codon, next_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        when "attenuate-maxT"
            attenuate_maxT_count(synonymous_codon, original_codon, pos, is_near_intron, dist_to_intron)
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

    def attenuate_count(synonymous_codon, next_codon, next_codon_synonyms, pos, is_near_intron, dist_to_intron)
        next_codon = "" unless next_codon # HOTFIX if codon is very last
        if _generates_CpG?(synonymous_codon, next_codon)
            # exception: upvote codon with both internal and cross-codon CpG
            if _generates_internal_CpG?(synonymous_codon) &&
                _generates_cross_neighbours_CpG?(synonymous_codon, next_codon)
                2
            else
                addend = synonymous_codon.count("AT")/3.to_f
                1 + addend
            end
        elsif _generates_TpA?(synonymous_codon, next_codon)
            # exception: cross-codon TpA will hinder CpG in next_codon
            # => disfavour cross-codon TpA
            if _hinders_CpG_in_next_codon?(synonymous_codon, next_codon, next_codon_synonyms)
                0
            else
                addend = synonymous_codon.count("AT")/3.to_f
                # tweak addend to ensure CpGs still rank higher
                0.99 + addend*(1-0.99)
            end
        else
            # score by usage in human genes while avoiding C's and G's
            multiplier = 1 - synonymous_codon.count("GC")/3.to_f
            _pessimal_human_score(synonymous_codon, pos, is_near_intron, dist_to_intron)*multiplier
        end
    end

    def attenuate_maxT_count(synonymous_codon, original_codon, pos, is_near_intron, dist_to_intron)
        multiplierT = 0.33
        multiplierA = 0.3
        if _increases_T?(synonymous_codon, original_codon)
            2 + multiplierT*_numT(synonymous_codon) + multiplierA*_numA(synonymous_codon)
        elsif _increases_A?(synonymous_codon, original_codon)
            0.99 + multiplierT*_numT(synonymous_codon) + multiplierA*_numA(synonymous_codon)
        else
            _pessimal_human_score(synonymous_codon, pos, is_near_intron, dist_to_intron)
        end
    end

    def _generates_CpG?(synonymous_codon, next_codon)
        _generates_cross_neighbours_CpG?(synonymous_codon, next_codon) || _generates_internal_CpG?(synonymous_codon)
    end

    def _generates_TpA?(synonymous_codon, next_codon)
        _generates_cross_neighbours_TpA?(synonymous_codon, next_codon) || _generates_internal_TpA?(synonymous_codon)
    end

    def _generates_cross_neighbours_CpG?(synonymous_codon, next_codon)
        synonymous_codon.end_with?("C") && next_codon.start_with?("G")
    end

    def _generates_internal_CpG?(synonymous_codon)
        # might be 1st/2nd site CpG or 2nd/3rd site CpG
        synonymous_codon.include?("CG")
    end

    def _generates_cross_neighbours_TpA?(synonymous_codon, next_codon)
        synonymous_codon.end_with?("T") && next_codon.start_with?("A")
    end

    def _generates_internal_TpA?(synonymous_codon)
        # might be 1st/2nd site CpG or 2nd/3rd site CpG
        synonymous_codon.include?("TA")
    end

    def _hinders_CpG_in_next_codon?(synonymous_codon, next_codon, next_codon_synonyms)
        # at least one of the codons synonymous to next_codon contains a CpG
        # but could not be selected due to restrictions on 1st site

        # NOTE - this checks if 1st site of _next_codon_ is restricted
        has_first_site_that_must_be_left_alone(synonymous_codon, next_codon) &&
            next_codon_synonyms.any? do |codon|
                _generates_internal_CpG?(codon) && codon[0] != next_codon[0]
            end
    end

    def _pessimal_human_score(synonymous_codon, pos, is_near_intron, dist_to_intron)
        score = 1 - gc_count(synonymous_codon, pos, is_near_intron, dist_to_intron)
        if score.infinite?
            # fix non-existing scores
            0
        else
            score
        end
    end

    def _increases_T?(synonymous_codon, original_codon)
        _numT(synonymous_codon) >= _numT(original_codon)
    end

    def _increases_A?(synonymous_codon, original_codon)
        _numA(synonymous_codon) >= _numA(original_codon)
    end

    def _numT(synonymous_codon)
        synonymous_codon.count("T")
    end

    def _numA(synonymous_codon)
        synonymous_codon.count("A")
    end
end