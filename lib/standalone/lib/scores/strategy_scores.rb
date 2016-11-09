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

    def weighted_scores(synonymous_codons, original_codon, pos)
        summed_scores = summed_up_codon_scores(synonymous_codons, original_codon, pos)

        synonymous_codons.collect do |synonymous_codon|
            this_score = codon_score(synonymous_codon, original_codon, pos)
            this_score/summed_scores.to_f
        end
    end

    private

    def is_known_strategy
        ["raw", "humanize", "gc"].include?(@strategy)
    end

    def is_strategy_data_defined
        case @strategy
        when "raw" then true
        when "humanize" then defined? Human_codon_counts
        when "gc" then defined? Third_site_counts
        end
    end

    def codon_score(synonymous_codon, original_codon, pos)
        case @strategy
        when "raw"
            raw_score(synonymous_codon, original_codon)
        when "humanize"
            humanize_score(synonymous_codon)
        when "gc"
            gc_score(synonymous_codon, pos)
        end
    end

    def raw_score(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def humanize_score(synonymous_codon)
        Human_codon_counts[synonymous_codon]
    end

    def gc_score(synonymous_codon, pos)
        if Third_site_counts[synonymous_codon].has_key?(pos)
            Third_site_counts[synonymous_codon][pos]
        else
            average_over_nearest_pos(Third_site_counts[synonymous_codon], pos)
        end
    end

    def summed_up_codon_scores(synonymous_codons, original_codon, pos)
        synonymous_codons.inject(0) do |sum, codon|
            sum + codon_score(codon, original_codon, pos)
        end
    end

    def average_over_nearest_pos(available_data, pos)
        sorted = available_data.keys.sort_by{|other| (pos-other).abs }
        nearest_pos = sorted.take(10)
        counts_nearest_pos = nearest_pos.collect{|pos| available_data[pos] }
        # calc average
        sum = counts_nearest_pos.inject(:+)
        len = counts_nearest_pos.size
        sum/len.to_f
    end
end