class ScoreSynonymousCodons

    def initialize(strategy, stay_in_subbox_for_6folds, ese_motifs, cds)
        @cds = cds
        @strategy_scorer = init_strategy_scorer(strategy)
        @ese_scorer = EseScores.new(ese_motifs)
        @choose_synonymous_codons_for_6folds_from_subbox = stay_in_subbox_for_6folds
    end

    def bestscoring_synonymous_codon_at(pos)
        orig_codon = get_codon_at(pos)
        syn_codons, scores = score_synonymous_codons_at(pos)
        best_codon = find_bestscoring_codon(syn_codons, scores)
        stick_to_orignal_codon_if_it_scores_equally_well(orig_codon, best_codon, syn_codons, scores)
    end

    def is_original_codon_scoring_best_at(pos, best_codon)
        orig_codon = get_codon_at(pos)
        best_codon == orig_codon
    end

    def log_bestscoring_codon_at(pos, best_codon)
        orig_codon = get_codon_at(pos)
        "Pos #{pos}: #{orig_codon} -> #{best_codon}"
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

    def score_synonymous_codons_at(pos)
        syn_codons = get_synonymous_codons_at(pos)
        strategy_scores = score_by_strategy(syn_codons, pos)
        ese_scores = score_by_ese(syn_codons, pos)
        combined_scores = combine_weighted_scores(strategy_scores, ese_scores)

        [syn_codons, combined_scores]
    end

    def find_bestscoring_codon(syn_codons, scores)
        highest_score_seen, codon_highest_score_seen = Float::MIN, nil
        syn_codons.each_with_index do |codon, ind|
            score = scores[ind]
            if score >= highest_score_seen
                highest_score_seen = score
                codon_highest_score_seen = codon
            end
        end
        codon_highest_score_seen
    end

    def stick_to_orignal_codon_if_it_scores_equally_well(orig_codon, best_codon, syn_codons, scores)
        score_orig_codon = scores[syn_codons.index(orig_codon)]
        score_best_codon = scores[syn_codons.index(best_codon)]

        score_orig_codon == score_best_codon ? orig_codon : best_codon
    end

    def score_by_strategy(syn_codons, pos)
        # NOTE: need orig_codon separately only because of raw-scorer
        orig_codon = get_codon_at(pos)
        @strategy_scorer.score(syn_codons, orig_codon, pos)
    end

    def score_by_ese(syn_codons, pos)
        windows_containing_syn_codons = syn_codons.collect do |codon|
            seq_part = get_mutated_subsequence_covering_all_windows(pos, codon)
            divide_into_windows(seq_part)
        end

        @ese_scorer.score(windows_containing_syn_codons)
    end

    def combine_weighted_scores(strategy_scores, ese_scores)
        strategy_scores.collect.with_index do |strategy_score, ind|
            ese_score = ese_scores[ind]
            strategy_score + ese_score
        end
    end

    def get_codon_at(pos)
        @cds[pos-2..pos]
    end

    def get_synonymous_codons(codon)
        # original codon always included
        # codons will be restricted to codon subbox depending on option set (relevant for 6-codon boxes only)
        if @choose_synonymous_codons_for_6folds_from_subbox
            GeneticCode.get_synonymous_codons_in_codon_box(codon)
        else
            GeneticCode.get_synonymous_codons(codon)
        end
    end

    def get_synonymous_codons_at(pos)
        orig_codon = get_codon_at(pos)
        get_synonymous_codons(orig_codon)
    end

    def get_mutated_subsequence_covering_all_windows(pos, codon)
        mutated_cds = mutate_codon_at(pos, codon)

        window_starts = get_startpositions_of_windows_containing_pos(pos)
        first_window_start = window_starts.first
        last_window_stop = window_starts.last + ind_last_pos_in_window

        mutated_cds[first_window_start..last_window_stop]
    end

    def divide_into_windows(seq_part)
        (0..seq_part.size-1).collect do |startpos|
            stoppos = startpos + ind_last_pos_in_window
            next if stoppos >= seq_part.size
            seq_part[startpos..stoppos]
        end.compact
    end

    def mutate_codon_at(pos, new_codon)
        tmp = String.new(@cds)
        tmp[pos-2..pos] = new_codon
        tmp
    end

    def get_startpositions_of_windows_containing_pos(pos)
        # need first two snippets only if codon at pos is 6-fold and option to choose from all 6 is set.
        codonstart = is_pos_treated_as_sixfold_site(pos) ? pos - 2 : pos
        codonstop = pos
        snippet_starts = ((codonstart-ind_last_pos_in_window)..codonstop)
        snippet_starts.reject do |startpos|
            stoppos = startpos + ind_last_pos_in_window
            startpos < 0 || stoppos >= @cds.size
        end
    end

    def is_pos_treated_as_sixfold_site(pos)
        get_synonymous_codons_at(pos).size == 6
    end

    def ind_last_pos_in_window
        Constants.window_size - 1
    end
end