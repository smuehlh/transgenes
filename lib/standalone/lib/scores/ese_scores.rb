class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def has_ese_motifs_to_score_by
        @ese_motifs.any?
    end

    def normalised_scores(windows_for_all_syn_codons)
        counts = windows_for_all_syn_codons.collect do |windows|
            count_non_eses(windows)
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def count_non_eses(windows)
        windows.count{|window| ! @ese_motifs.has_key?(window)}
    end
end