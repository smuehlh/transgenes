class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def weighted_scores(windows_for_all_syn_codons)
        if @ese_motifs.any?
            # score windows accoring to their ese resemblance
            windows_for_all_syn_codons.collect do |windows|
                ese_count(windows)/max_count(windows).to_f
            end
        else
            # set all scores to 0
            Array.new(windows_for_all_syn_codons.size) {0}
        end
    end

    def max_score
        @ese_motifs.any? ? 1 : 0
    end

    private

    def ese_count(windows)
        (windows - @ese_motifs).size
    end

    def max_count(windows)
        windows.size
    end
end