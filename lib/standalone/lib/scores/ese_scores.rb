class EseScores

    def initialize(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def normalised_scores(windows_for_all_syn_codons)
        if @ese_motifs.any?
            # score windows accoring to their ese resemblance
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
       else
            # set all scores to 0
            Array.new(windows_for_all_syn_codons.size) {0}
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