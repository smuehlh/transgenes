class EseScores

    def initialize(ese_motifs, strategy)
        @ese_motifs = ese_motifs
        @strategy = strategy
        ErrorHandling.abort_with_error_message(
            "unknown_ese_strategy", "EseScores"
        ) unless is_known_strategy
    end

    def has_ese_motifs_to_score_by
        @ese_motifs.any?
    end

    def normalised_scores(windows_for_all_syn_codons)
        counts = windows_for_all_syn_codons.collect do |windows|
            case @strategy
            when "deplete" then count_non_eses(windows)
            when "enrich" then count_eses(windows)
            end
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(counts)
    end

    private

    def is_known_strategy
        ["deplete", "enrich"].include?(@strategy)
    end

    def count_eses(windows)
        windows.count{|window| @ese_motifs.has_key?(window)}
    end

    def count_non_eses(windows)
        windows.size - count_eses(windows)
    end
end