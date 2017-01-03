class ScoreSynonymousCodons

    def initialize(strategy, stay_in_subbox_for_6folds, ese_motifs, exons, introns)
        @cds = exons.join("")
        @synonymous_sites = SynonymousSites.new(exons, introns)
        @strategy_scorer = StrategyScores.new(strategy)
        @ese_scorer = EseScores.new(ese_motifs)
        @choose_synonymous_codons_for_6folds_from_subbox = stay_in_subbox_for_6folds
    end

    def synonymous_sites_in_cds
        @synonymous_sites.get_synonymous_sites_in_cds
    end

    def select_synonymous_codon_at(pos)
        syn_codons, scores = score_synonymous_codons_at(pos)
        select_codon_matching_random_score(syn_codons, scores)
    end

    def is_original_codon_selected_at(pos, best_codon)
        orig_codon = get_codon_at(pos)
        best_codon == orig_codon
    end

    def log_selected_codon_at(pos, best_codon)
        orig_codon = get_codon_at(pos)
        "Pos #{pos}: #{orig_codon} -> #{best_codon}"
    end

    private

    def score_synonymous_codons_at(pos)
        syn_codons = get_synonymous_codons_at(pos)
        scores =
            if is_stopcodon_at(pos)
                score_stopcodons(syn_codons)
            elsif @synonymous_sites.is_in_proximity_to_deleted_intron(pos) &&
                @ese_scorer.has_ese_motifs_to_score_by
                # additionally score by ese resemblance
                # NOTE: ese input is optional and might have been omitted
                strategy_scores = score_by_strategy(syn_codons, pos)
                ese_scores = score_by_ese(syn_codons, pos)
                combine_normalised_scores(strategy_scores, ese_scores)
            else
                # pure strategy scores
                score_by_strategy(syn_codons, pos)
            end

        [syn_codons, scores]
    end

    def select_codon_matching_random_score(syn_codons, scores)
        # NOTE: assuming that scores are between 0 and 1
        random_score = rand()
        sum = 0
        syn_codons.each_index do |ind|
            codon = syn_codons[ind]
            sum += scores[ind]
            return codon if random_score <= sum
        end
    end

    def score_by_strategy(syn_codons, pos)
        orig_codon = get_codon_at(pos)
        is_near_intron = @synonymous_sites.is_in_proximity_to_intron(pos)
        distance_to_intron = @synonymous_sites.get_nt_distance_to_intron(pos)

        @strategy_scorer.normalised_scores(syn_codons, orig_codon, pos, is_near_intron, distance_to_intron)
    end

    def score_by_ese(syn_codons, pos)
        windows_containing_syn_codons = syn_codons.collect do |codon|
            seq_part = get_mutated_subsequence_covering_all_windows(pos, codon)
            divide_into_windows(seq_part)
        end

        @ese_scorer.normalised_scores(windows_containing_syn_codons)
    end

    def score_stopcodons(syn_codons)
        syn_codons.collect do |codon|
            codon == "TAA" ? 1 : 0
        end
    end

    def combine_normalised_scores(strategy_scores, ese_scores)
        combined_scores = strategy_scores.each_index.collect do |ind|
            strategy_scores[ind] * ese_scores[ind]
        end
        Statistics.normalise(combined_scores)
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

    def is_stopcodon_at(pos)
        orig_codon = get_codon_at(pos)
        GeneticCode.is_stopcodon(orig_codon)
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