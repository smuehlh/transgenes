class ScoreSynonymousCodons

    def initialize(strategy, exons, ese_motifs)
        @sequence = exons.join("")
        init_scoring_objects(strategy, ese_motifs)
    end

    def score_synonymous_codons_at(pos)
        init_vars_describing_codon_and_position(pos)
        score_synonymous_codons
        sort_synonymous_codons_by_score
    end

    def is_codon_not_the_original(codon)
        @original_codon != codon
    end

    def log_changes
        codons_with_scores =
            @sorted_synonymous_codons.collect.each_with_index do |codon, ind|
                score = -@sorted_scores[ind].round(2)
                "#{codon}: #{score}"
            end.join(", ")
        "#{@pos}: #{@original_codon} -> #{@sorted_synonymous_codons.first}\n\t#{codons_with_scores}\n"
    end

    private

    def init_scoring_objects(strategy, ese_motifs)
        @strategy_scoring_obj =
            case strategy
            when "raw" then RawSequenceScores.new
            when "humanize" then HumanMatchedSequenceScores.new
            when "gc"
            else
                # hopefully this will be never executed.
                ErrorHandling.abort_with_error_message("unknown_strategy")
            end
        @ese_scoring_obj = EseScores.new(ese_motifs)
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

    def get_codon_at_pos
        @sequence[@pos-2..@pos]
    end

    def get_synonymous_codons
        # includes original codon
        GeneticCode.get_synonymous_codon(@original_codon)
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
            @strategy_scoring_obj.score_synonymous_codon_by_strategy(
                synonymous_codon, @original_codon
            )
        ese_score =
            @ese_scoring_obj.score_synonymous_codon_by_ese_resemblance(windows)

        combine_scores(strategy_score, ese_score)
    end

    def combine_scores(strategy_score, ese_score)
        # assume the scores are already weighted and just need to be combined!
        strategy_score + ese_score
    end
end