class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr, :sequence, :description

    def initialize
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @sequence = "" # UTRs, exons and introns merged together

        @ese_motifs = []
    end

    def add_cds(exons, introns, gene_name)
        @exons = exons
        @introns = introns
        @description = gene_name

        @sequence = combine_features_to_sequence
    end

    def add_five_prime_utr(exons, introns, dummy)
        @five_prime_utr = combine_exons_and_introns(exons, introns)
        @sequence = combine_features_to_sequence
    end

    def add_three_prime_utr(exons, introns, dummy)
        @three_prime_utr = combine_exons_and_introns(exons, introns)
        @sequence = combine_features_to_sequence
    end

    def add_ese_list(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def remove_introns(is_remove_first_intron)
        @introns = is_remove_first_intron ? [] : [@introns.first]
        @sequence = combine_features_to_sequence
    end

    def print_statistics
        str = "Number of exons: #{@exons.size}"
        first_intron_kept = @introns.size == 1
        str += "\nAll introns " + (first_intron_kept ? "but" : "including") + " the first removed."
        str += "\nTotal mRNA size: #{@sequence.size}"
        str
    end

    def tweak_sequence(options)
        syn_sites = SynonymousSites.new(@exons, @introns)
        syn_sites.get_synonymous_sites_in_exons.each do |pos|
            codon = get_codon_in_exon(pos)
            synonymous_codons = get_synonymous_codons(codon)
            next if synonymous_codons.size == 1 # nothing to do.

            scores = score_synonymous_codons(synonymous_codons, pos)
            best_scoring_codon = select_synonymous_codon_with_highest_score(scores, synonymous_codons)

            replace_codon_at_pos(pos, best_scoring_codon) unless best_scoring_codon == codon
        end

        # combine sequences
        @sequence = combine_features_to_sequence
    end

    private

    def combine_features_to_sequence
        [
            @five_prime_utr,
            combine_exons_and_introns(@exons, @introns),
            @three_prime_utr
        ].join("")
    end

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def get_codon_in_exon(pos)
        @exons.join("")[pos-2..pos]
    end

    def get_synonymous_codons(codon)
        # original codon is always the first in list
        synonymous_codons = GeneticCode.get_synonymous_codon(codon)
        synonymous_codons.unshift(codon).uniq
    end

    def score_synonymous_codons(synonymous_codons, pos)
        snippets = get_sequence_snippets_containing_pos(pos)

        scores = synonymous_codons.collect do |codon|
            if codon == synonymous_codons.first
                # assume the original codon is the first in list
                is_original_codon = true
                windows = snippets
            else
                is_original_codon = false
                windows = mutate_sequence_snippets(snippets, codon)
            end

            strategy_score = score_codon_by_strategy(codon, is_original_codon)
            ese_score = score_codon_by_ese_resemblance(windows)
            weight_scores(strategy_score, ese_score, windows)
        end
    end

    def score_codon_by_strategy(codon, is_original_codon)
        # strategy: raw sequence
        is_original_codon ? 1 : 0
    end

    def max_score_by_strategy
        1
    end

    def score_codon_by_ese_resemblance(windows)
        # NOTE: this depends on the window size.
        (windows - @ese_motifs).size
    end

    def max_score_by_ese_resemblance(windows)
        windows.size
    end

    def weight_scores(strategy_score, ese_score, windows)
        strategy_score/max_score_by_strategy.to_f +
            ese_score/max_score_by_ese_resemblance(windows).to_f
    end

    def select_synonymous_codon_with_highest_score(scores, codons)
        # obtain the first index
        # this will favor the original codon, as it is first in list
        ind_of_highest_score = scores.index(scores.max)
        codons[ind_of_highest_score]
    end

    def get_sequence_snippets_containing_pos(pos)
        max_distance_to_pos = 5
        seq = @exons.join("")
        ((pos-max_distance_to_pos)..pos).collect do |startpos|
            stoppos = startpos + max_distance_to_pos
            if startpos < 0 || stoppos >= seq.size
                nil
            else
                seq[startpos..stoppos]
            end
        end.compact
    end

    def mutate_sequence_snippets(windows, new_codon)
        pos = 5 # NOTE: this depends on the value of 'max_distance_to_pos'
        windows.collect do |window|
            window[pos] = mutated_nucleotide(new_codon)
            pos -= 1
            window
        end
    end

    def replace_codon_at_pos(pos, new_codon)
        @exons.each do |exon|
            if pos >= exon.size
                pos -= exon.size
            else
                exon[pos] = mutated_nucleotide(new_codon)
                break
            end
            exon
        end
    end

    def mutated_nucleotide(codon)
        codon.chars.last
    end
end