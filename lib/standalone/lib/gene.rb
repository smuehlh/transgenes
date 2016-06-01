class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr, :sequence, :description

    def initialize
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @sequence = "" # UTRs, exons and introns merged together
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

    def remove_introns(is_remove_first_intron)
        # NOTE: save first intron, as this method might be called multiple times with different parameters.
        @first_intron = @introns.first
        @introns = is_remove_first_intron ? [] : [@first_intron]
        @sequence = combine_features_to_sequence
    end

    def print_statistics
        str = "Number of exons: #{@exons}"
        first_intron_kept = @introns.size == 1
        str += "\nAll introns " + (first_intron_kept ? "but" : "including") + " the first removed."
        str += "\nTotal mRNA size: #{@sequence.size}"
        str
    end

    def tweak_sequence(options)
        # do stuff.
        # remove splice sites flanking now removed introns.

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

    def destroy_ese_sequences
        # only if minimum number of exons found.
    end

    def humanize_codon_usage

    end
end
