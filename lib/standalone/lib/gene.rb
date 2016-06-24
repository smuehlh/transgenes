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

            windows = get_sequence_snippets_containing_pos(pos)
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
end