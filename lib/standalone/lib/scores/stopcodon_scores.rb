class StopcodonScores

    def self.normalised_scores(synonymous_codons)
        scorer = StopcodonScores.new
        scorer.normalised_scores(synonymous_codons)
    end

    def normalised_scores(synonymous_codons)
        counts = synonymous_codons.collect do |synonymous_codon|
            raw_count(synonymous_codon)
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def raw_count(synonymous_codon)
        synonymous_codon == "TAA" ? 1 : 0
    end
end