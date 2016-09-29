class GcMatchedSequenceScores

    def initialize
    end

    def score_synonymous_codon_by_strategy(synonymous_codon, dummy)
        actual_score(synonymous_codon)/max_score.to_f
    end

    private

    def actual_score(synonymous_codon)
        # select for high GC content
        synonymous_codon.count("C") + synonymous_codon.count("G")
    end

    def max_score
        3
    end
end