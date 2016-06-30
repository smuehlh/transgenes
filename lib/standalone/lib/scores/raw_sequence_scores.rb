class RawSequenceScores

    def initialize(original_codon, ese_motifs)
        @original_codon = original_codon
        @ese_motifs = ese_motifs
    end

    def score_synonymous_codon(windows, codon, is_original_codon)
        strategy_score = score_codon_by_strategy(codon)
        ese_score = score_codon_by_ese_resemblance(windows)
        weight_scores(strategy_score, ese_score, windows)
    end

    private

    def score_codon_by_strategy(is_original_codon)
        is_original_codon ? 1 : 0
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