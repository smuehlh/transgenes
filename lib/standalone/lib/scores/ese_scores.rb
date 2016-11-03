class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def score(windows_for_all_syn_codons)
        windows_for_all_syn_codons.collect do |windows|
            actual_score(windows)/max_score(windows).to_f
        end
    end

    private

    def actual_score(windows)
        (windows - @ese_motifs).size
    end

    def max_score(windows)
        windows.size
    end
end