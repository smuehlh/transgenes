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

    def set_options(options)
        @keep_first_intron = ! options[:remove_first_intron]
        # tweak sequence options.
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

    def tweak_sequence
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

    def remove_unwanted_introns
        @introns = @keep_first_intron ? [@introns.shift] : []
    end

end
