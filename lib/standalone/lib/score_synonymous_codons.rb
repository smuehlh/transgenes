class ScoreSynonymousCodons

    def initialize(exons, ese_motifs)
        @sequence = exons.join("")
        init_scoring_obj(ese_motifs)
    end

    def score_synonymous_codons_at(pos)
        init_vars_describing_codon_and_position(pos)
        score_synonymous_codons
        sort_synonymous_codons_by_score
    end

    def is_codon_not_the_original(codon)
        @original_codon != codon
    end

    private

    def init_scoring_obj(ese_motifs)
        @score_obj = RawSequenceScores.new(ese_motifs)
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
            @score_obj.score_synonymous_codon(windows, codon, @original_codon)
        end
    end

    def sort_synonymous_codons_by_score
        sorted_scores = @scores.sort.reverse
        sorted_scores.each_with_index.collect do |score, ind|
            @synonymous_codons[ind]
        end
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

end