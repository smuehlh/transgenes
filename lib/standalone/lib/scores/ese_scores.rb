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
        sum = Statistics.sum(counts)
        if sum == 0
            # all syn_codons are equally (un-)likely. avoid diving by 0
            equal_scores_for(windows_for_all_syn_codons.size)
        else
            Statistics.normalise(counts, sum)
        end
    end

    private

    def count_non_eses(windows)
        (windows - @ese_motifs).size
    end

    def equal_scores_for(n)
        Array.new(n) {1/n.to_f}
    end
end