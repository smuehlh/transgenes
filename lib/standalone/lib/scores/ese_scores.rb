class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def weighted_scores(windows_for_all_syn_codons)
        windows_for_all_syn_codons.collect do |windows|
            ese_count(windows)/max_count(windows).to_f
        end
    end

    def max_score
        1
    end

    private

    def ese_count(windows)
        (windows - @ese_motifs).size
    end

    def max_count(windows)
        windows.size
    end
end