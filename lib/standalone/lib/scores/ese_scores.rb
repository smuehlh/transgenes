class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def score_synonymous_codon_by_ese_resemblance(windows)
        actual_score(windows)/max_score(windows).to_f
    end

    private

    def actual_score(windows)
        (windows - @ese_motifs).size
    end

    def max_score(windows)
        windows.size
    end
end