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
        synonymous_sites.each do |pos|
            codon = get_codon_in_exon(pos)
            synonymous_codons = get_synonymous_codons(codon)
            next if synonymous_codons.size == 1 # nothing to do.

            best_scoring_codon = score_synonymous_codons(synonymous_codons, pos)
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

    def synonymous_sites
        # synonymous sites (= 3. codon positions)
        first_synonymous_site = 2
        last_synonymous_site = @exons.join("").size - 1
        (first_synonymous_site..last_synonymous_site).step(3)
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
            weight_scores(strategy_score, ese_score)
        end
        select_synonymous_codon_with_highest_score(scores, synonymous_codons)
    end

    def score_codon_by_strategy(codon, is_original_codon)
        1
    end

    def max_score_by_strategy
        1
    end

    def score_codon_by_ese_resemblance(windows)
        1
    end

    def max_score_by_ese_resemblance
        # NOTE: this depends on the number of sequence snippets containing a given position
        6
    end

    def weight_scores(strategy_score, ese_score)
        strategy_score/max_score_by_strategy.to_f +
            ese_score/max_score_by_ese_resemblance.to_f
    end

    def select_synonymous_codon_with_highest_score(scores, codons)
        # obtain the first index
        # this will favor the original codon, as it is first in list
        ind_of_lowest_score = scores.index(scores.min)
        codons[ind_of_lowest_score]
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
            window[pos] = new_codon.chars.last
            pos -= 1
            window
        end
    end
end