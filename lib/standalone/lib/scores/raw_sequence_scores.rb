class RawSequenceScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def score_synonymous_codon(windows, synonymous_codon, original_codon)
        strategy_score = score_codon_by_strategy(
            synonymous_codon, original_codon)
        ese_score = score_codon_by_ese_resemblance(windows)
        weight_scores(strategy_score, ese_score, windows)
    end

    private

    def score_codon_by_strategy(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def max_score_by_strategy
        1
    end

    def score_codon_by_ese_resemblance(windows)
        (windows - @ese_motifs).size
    end

    def max_score_by_ese_resemblance(windows)
        windows.size
    end

    def weight_scores(strategy_score, ese_score, windows)
        strategy_score/max_score_by_strategy.to_f +
            ese_score/max_score_by_ese_resemblance(windows).to_f
    end
end