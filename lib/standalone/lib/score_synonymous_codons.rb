class ScoreSynonymousCodons

    def initialize(strategy, ese_strategy, score_eses_at_all_sites, synonymous_sites, ese_motifs)
        @strategy_scorer = StrategyScores.new(strategy)
        @synonymous_sites = synonymous_sites
        @ese_scorer = EseScores.new(ese_motifs, ese_strategy)
        @is_scoring_eses_at_each_site = score_eses_at_all_sites
    end

    def select_synonymous_codon_at(cds_tweaked_up_to_pos, pos)
        syn_codons, scores = score_synonymous_codons_at(cds_tweaked_up_to_pos, pos)
        select_codon_matching_random_score(syn_codons, scores)
    end

    def is_original_codon_selected_at(pos, best_codon)
        orig_codon = @synonymous_sites.original_codon_at(pos)
        best_codon == orig_codon
    end

    def log_selected_codon_at(pos, best_codon)
        orig_codon = @synonymous_sites.original_codon_at(pos)
        "Pos #{Counting.ruby_to_human(pos)}: #{orig_codon} -> #{best_codon}"
    end

    private

    def score_synonymous_codons_at(cds_tweaked_up_to_pos, pos)
        syn_codons = @synonymous_sites.synonymous_codons_at(pos)
        strategy_scores =
            if @synonymous_sites.is_stopcodon_at(pos)
                score_stopcodons(pos)
            else
                score_by_strategy(pos)
            end
        scores =
            if @ese_scorer.has_ese_motifs_to_score_by &&
                (@is_scoring_eses_at_each_site ||
                @synonymous_sites.is_in_proximity_to_deleted_intron(pos))

                # additionally score by ese resemblance
                # NOTE: ese input is optional and might have been omitted
                ese_scores = score_by_ese(cds_tweaked_up_to_pos, pos)

                if @strategy_scorer.is_strategy_to_select_for_original_codon
                    # pure ese scores (as is intended by this particular strategy)
                    # NOTE: the combining method would fail here anyways
                    # (strategy scores are 0's or 1 and would therefore overwrite ese scores)
                    ese_scores
                else
                    combine_normalised_scores(strategy_scores, ese_scores)
                end
            else
                # pure strategy scores
                strategy_scores
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

    def score_by_strategy(pos)
        orig_codon = @synonymous_sites.original_codon_at(pos)
        syn_codons = @synonymous_sites.synonymous_codons_at(pos)
        is_near_intron = @synonymous_sites.is_in_proximity_to_intron(pos)
        distance_to_intron = @synonymous_sites.get_nt_distance_to_intron(pos)
        next_codon = @synonymous_sites.neighbouring_codon_at(pos)

        @strategy_scorer.normalised_scores(syn_codons, orig_codon, pos, is_near_intron, distance_to_intron)
    end

    def score_by_ese(cds_tweaked_up_to_pos, pos)
        windows = @synonymous_sites.sequence_windows_covering_syn_codons_at(cds_tweaked_up_to_pos, pos)

        @ese_scorer.normalised_scores(windows)
    end

    def score_stopcodons(pos)
        syn_codons = @synonymous_sites.synonymous_codons_at(pos)

        StopcodonScores.normalised_scores(syn_codons)
    end

    def combine_normalised_scores(strategy_scores, ese_scores)
        combined_scores = strategy_scores.each_index.collect do |ind|
            strategy_scores[ind] * ese_scores[ind]
        end
        Statistics.normalise_scores_or_set_equal_if_all_scores_are_zero(combined_scores)
    end
end