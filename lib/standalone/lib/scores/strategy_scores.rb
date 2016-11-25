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

    def normalised_scores(synonymous_codons, original_codon, pos)
        counts = synonymous_codons.collect do |synonymous_codon|
            codon_count(synonymous_codon, original_codon, pos)
        end
        sum = Statistics.sum(counts)
        Statistics.normalise(counts, sum)
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

    def codon_count(synonymous_codon, original_codon, pos)
        case @strategy
        when "raw"
            raw_count(synonymous_codon, original_codon)
        when "humanize"
            humanize_count(synonymous_codon)
        when "gc"
            gc_count(synonymous_codon, pos)
        end
    end

    def raw_count(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def humanize_count(synonymous_codon)
        Human_codon_counts[synonymous_codon]
    end

    def gc_count(synonymous_codon, pos)
        # NOTE pos is nucleotide pos in CDS whereas Third_site_counts are amino acid positions
        aa_pos = pos/3
        if Third_site_counts[synonymous_codon].has_key?(aa_pos)
            Third_site_counts[synonymous_codon][aa_pos]
        else
            average_over_nearest_pos(Third_site_counts[synonymous_codon], aa_pos)
        end
    end

    def average_over_nearest_pos(available_data, pos)
        sorted = available_data.keys.sort_by{|other| (pos-other).abs }
        nearest_pos = sorted.take(10)
        counts_nearest_pos = nearest_pos.collect{|pos| available_data[pos] }
        Statistics.mean(counts_nearest_pos)
    end
end