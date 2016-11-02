class ScoreSynonymousCodons

    def initialize(strategy, stay_in_subbox_for_6folds, exons, ese_motifs)
        @sequence = exons.join("")
        @strategy_scorer = init_strategy_scorer(strategy)
        @ese_scorer = EseScores.new(ese_motifs)
        @choose_synonymous_codons_for_6folds_from_subbox = stay_in_subbox_for_6folds
    end

    def score_synonymous_codons_at(pos)
        init_vars_describing_codon_and_position(pos)
        score_synonymous_codons
        sort_synonymous_codons_by_score
        select_bestscoring_codon
    end

    def is_bestscoring_codon_not_the_original_codon
        @original_codon != @bestscoring_synonymous_codon
    end

    def log_changes
        codons_with_scores =
            @sorted_synonymous_codons.collect.each_with_index do |codon, ind|
                score = -@sorted_scores[ind].round(2)
                "#{codon}: #{score}"
            end.join(", ")
        "Pos #{@pos}: #{@original_codon} -> #{@sorted_synonymous_codons.first} (#{codons_with_scores})"
    end

    private

    def init_strategy_scorer(strategy)
        case strategy
        when "raw" then RawSequenceScores.new
        when "humanize" then HumanMatchedSequenceScores.new
        when "gc" then GcMatchedSequenceScores.new
        else
            ErrorHandling.abort_with_error_message(
                "unknown_strategy", "ScoreSynonymousCodons"
            )
        end
    end

    def init_vars_describing_codon_and_position(pos)
        @pos = pos
        @original_codon = get_codon_at_pos
        @synonymous_codons = get_synonymous_codons # including original codon
        @snippet_starts = get_startpositions_of_snippets_containing_pos
    end

    def score_synonymous_codons
        @scores = @synonymous_codons.collect do |codon|
            windows = get_sequence_snippets(codon)
            score_synonymous_codon(windows, codon)
        end
    end

    def sort_synonymous_codons_by_score
        indices = (0..@scores.size-1)
        negative_scores_with_indices = @scores.map{ |x| -x }.zip(indices)
        sorted_scores_with_original_index = negative_scores_with_indices.sort
        @sorted_synonymous_codons, @sorted_scores = [], []
        sorted_scores_with_original_index.collect do |score, ind|
            @sorted_synonymous_codons.push(@synonymous_codons[ind])
            @sorted_scores.push(score)
        end
        @sorted_synonymous_codons
    end

    def select_bestscoring_codon
        @bestscoring_synonymous_codon = @sorted_synonymous_codons.first
    end

    def get_codon_at_pos
        @sequence[@pos-2..@pos]
    end

    def get_synonymous_codons
        # original codon always included
        # codons will be restricted to codon subbox depending on option set (relevant for 6-codon boxes only)
        if @choose_synonymous_codons_for_6folds_from_subbox
            GeneticCode.get_synonymous_codons_in_codon_box(@original_codon)
        else
            GeneticCode.get_synonymous_codons(@original_codon)
        end
    end

    def get_startpositions_of_snippets_containing_pos
        snippet_starts = ((@pos-max_distance_in_sequence_snippets_to_pos)..@pos)
        snippet_starts.reject do |startpos|
            stoppos = startpos + max_distance_in_sequence_snippets_to_pos
            startpos < 0 || stoppos >= @sequence.size
        end
    end

    def get_sequence_snippets(codon)
        mutated_sequence = @original_codon ? @sequence : mutate_codon_to(codon)
        @snippet_starts.collect do |startpos|
            stoppos = startpos + max_distance_in_sequence_snippets_to_pos
            mutated_sequence[startpos..stoppos]
        end
    end

    def mutate_codon_to(new_codon)
        # FIXME: replace complete codon, not just the third site.
        head = @sequence[0..@pos-1]
        mutation = new_codon.chars.last
        tail = @sequence[@pos+1..-1]
        [head, mutation, tail].join("")
    end

    def mutate_sequence_snippets(new_codon)
        pos = max_distance_in_sequence_snippets_to_pos
        @original_sequence_snippets.collect do |window|
            window[pos] = new_codon.chars.last
            pos -= 1
            window
        end.compact
    end

    def max_distance_in_sequence_snippets_to_pos
        Constants.window_size - 1
    end

    def score_synonymous_codon(windows, synonymous_codon)
        strategy_score =
            @strategy_scorer.score_synonymous_codon_by_strategy(
                synonymous_codon, @original_codon
            )
        ese_score =
            @ese_scorer.score_synonymous_codon_by_ese_resemblance(windows)

        combine_scores(strategy_score, ese_score)
    end

    def combine_scores(strategy_score, ese_score)
        # assume the scores are already weighted and just need to be combined!
        strategy_score + ese_score
    end
end