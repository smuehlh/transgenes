class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr

    def initialize
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged
    end

    def add_cds(file, use_gene_starting_in_line)
        parse_gene_file(file, use_gene_starting_in_line, "CDS")
        save_gene_as_cds
    end

    def add_utr(file, use_gene_starting_in_line, is_5prime_utr)
        # INFO: file might not exist.
        if file
            use_feature = is_5prime_utr ? "5'UTR" : "3'UTR"
            parse_gene_file(file, use_gene_starting_in_line, use_feature)
            save_gene_as_utr(is_5prime_utr)
        else
            # file does not exist. nothing to do: work with empty utr-sequences
        end
    end

    def statistics
        stats = GeneStatistics.new(self)
        stats.print
    end

    def combine_features_into_sequence
        [
            @five_prime_utr,
            @exons.zip(@introns),
            @three_prime_utr
        ].flatten.compact.join("")
    end

    def tweak_sequence
        # do stuff.

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
        # only if minimum number of exons found.
        # remove intron and change corresponding splice site
    end

    private

    def parse_gene_file(file, use_gene_starting_in_line, use_feature)
        @to_gene_obj = ToGene.new(use_feature)
        @to_gene_obj.parse_file_or_die(file, use_gene_starting_in_line)
    end

    def save_gene_as_cds
        @description = @to_gene_obj.gene_name
        @exons = @to_gene_obj.exons
        @introns = @to_gene_obj.introns
    end

    def save_gene_as_utr(is_5prime_utr)
        if is_5prime_utr
            @five_prime_utr = @to_gene_obj.get_sequence
        else
            @three_prime_utr = @to_gene_obj.get_sequence
        end
    end
end
