class GcMatchedSequenceScores

    def initialize
        # ensure counts-matrix has been loaded
        ErrorHandling.abort_with_error_message(
            "missing_strategy_matrix", "GcMatchedSequenceScores"
        ) unless defined?(Third_site_counts)
    end

    def score_synonymous_codon_by_strategy(synonymous_codons, dummy)
        synonymous_codons.collect do |synonymous_codon|
            actual_score(synonymous_codon)/max_score(synonymous_codons).to_f
        end
    end

    private

    def actual_score(synonymous_codon)
        # FIXME: retrieve from table
    end

    def max_score(synonymous_codons)
        # FIXME: sum of syn-codon scores
    end
end