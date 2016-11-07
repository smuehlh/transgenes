class RawSequenceScores

    def initialize
    end

    def score(synonymous_codons, original_codon, dummy)
        synonymous_codons.collect do |synonymous_codon|
            actual_score(synonymous_codon, original_codon)/max_score.to_f
        end
    end

    private

    def actual_score(synonymous_codon, original_codon)
        synonymous_codon == original_codon ? 1 : 0
    end

    def max_score
        1
    end
end