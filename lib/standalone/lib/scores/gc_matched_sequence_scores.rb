class GcMatchedSequenceScores

    def initialize
    end

    def score_synonymous_codon_by_strategy(synonymous_codons, dummy)
        synonymous_codons.collect do |synonymous_codon|
            actual_score(synonymous_codon)/max_score.to_f
        end
    end

    private

    def actual_score(synonymous_codon)
        # FIXME: retrieve from table
    end

    def max_score
        # FIXME: sum of syn-codon scores
    end
end