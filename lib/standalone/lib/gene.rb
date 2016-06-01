class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr

    def initialize
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged
    end

    def add_cds(exons, introns, gene_name)
        @exons = exons
        @introns = introns
        @description = gene_name
    end

    def add_five_prime_utr(exons, introns, dummy)
        @five_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def add_three_prime_utr(exons, introns, dummy)
        @three_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def statistics
        stats = GeneStatistics.new(self)
        stats.print
    end

    def combine_features_into_sequence
        [
            @five_prime_utr,
            combine_exons_and_introns(@exons, @introns),
            @three_prime_utr
        ].join("")
    end

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def tweak_sequence(options)
        # do stuff.
        # remove splice sites flanking now removed introns.

        # combine sequences
        @sequence = combine_features_into_sequence
    end

    def formatting_to_fasta
        GeneToFasta.formatting(@description, @sequence)
    end

    def destroy_ese_sequences
        # only if minimum number of exons found.
    end

    def humanize_codon_usage

    end

    def remove_introns(is_remove_first_intron)
        # NOTE: save first intron, as this method might be called multiple times with different parameters.
        @first_intron = @introns.first
        @introns = is_remove_first_intron ? [] : [@first_intron]
    end

end
