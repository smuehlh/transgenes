class StrategyScores
    attr_writer :is_near_intron

    def initialize(strategy)
        @is_near_intron = false # re-set for each position to score
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
        when "gc"
            defined?(Third_site_frequencies) &&
            defined?(Third_site_counts_near_intron)
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
        # NOTE pos is a nucleotide pos whereas Third_site_counts is in amino acid positions
        aa_pos = pos/3
        if @is_near_intron
            Third_site_counts_near_intron[synonymous_codon][aa_pos]
        else
            Third_site_frequencies[synonymous_codon].(aa_pos)
        end
    end
end