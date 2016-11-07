class GcMatchedSequenceScores

    def initialize
        # ensure counts-matrix has been loaded
        ErrorHandling.abort_with_error_message(
            "missing_strategy_matrix", "GcMatchedSequenceScores"
        ) unless defined?(Third_site_counts)
    end

    def score(synonymous_codons, dummy, pos)
        synonymous_codons.collect do |synonymous_codon|
            actual_score(synonymous_codon, pos)/max_score(synonymous_codons, pos).to_f
        end
    end

    private

    def actual_score(synonymous_codon, pos)
        # FIXME: convert to frequencies?
        Third_site_counts[synonymous_codon][pos]
    end

    def max_score(synonymous_codons)
        synonymous_codons.inject(0){|sum, codon| sum + Third_site_counts[codon][pos]}
    end
end