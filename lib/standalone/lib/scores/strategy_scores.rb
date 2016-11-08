class StrategyScores

    def initialize(strategy)
        @strategy = strategy
        ErrorHandling.abort_with_error_message(
            "unknown_strategy", "StrategyScores"
        ) unless is_known_strategy
        # TODO
        # ensure matrices are found.
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
        Third_site_counts[synonymous_codon][pos]
    end

    def summed_up_codon_scores(synonymous_codons, original_codon, pos)
        synonymous_codons.inject(0) do |sum, codon|
            sum + codon_score(codon, original_codon, pos)
        end
    end
end