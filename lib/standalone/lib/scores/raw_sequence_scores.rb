class RawSequenceScores

    def initialize
    end

    def score_synonymous_codon_by_strategy(synonymous_codon, original_codon)
        actual_score(synonymous_codon, original_codon)/max_score.to_f
    end

    private

    def actual_score(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def max_score
        1
    end
end