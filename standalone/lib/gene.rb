class Gene

    def initialize(file, use_gene_starting_in_line)
        init_gene_features
        parse_gene_file(file, use_gene_starting_in_line)
        save_gene
    end

    def add_utr(utr_obj_5prime, utr_obj_3prime)
        @five_prime_utr = utr_obj_5prime.get_sequence
        @three_prime_utr = utr_obj_3prime.get_sequence
    end

    def statistics
        str = ""
        # if @utr_5prime
            # str += "5' UTR"
            # str += ", #{@utr_5prime.exons.size} Exons, #{@utr_5prime.introns.size} Introns"
            # str += "\n"
        # end
        str += "#{@exons.size} Exons\n"
        str += "#{@introns.size} Introns"
        # if @utr_3prime
        #     str += "\n"
        #     str += "3' UTR"
        #     str += ", #{@utr_3prime.exons.size} Exons, #{@utr_3prime.introns.size} Introns"
        # end
        str += "\n"
        str += "Total sequence length: #{combine_features_into_sequence.size} nucleotides."
        str
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

    def init_gene_features
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = ""
        @three_prime_utr = ""
    end

    def parse_gene_file(file, use_gene_starting_in_line)
        @to_gene_obj = ToGene.new()
        @to_gene_obj.parse_file_to_gene_data_or_die(file, use_gene_starting_in_line)
    end

    def save_gene
        @description = @to_gene_obj.gene_name
        @exons = @to_gene_obj.exons
        @introns = @to_gene_obj.introns
    end

    def combine_features_into_sequence
        [
            @five_prime_utr,
            @exons.zip(@introns),
            @three_prime_utr
        ].flatten.join("")
    end
end
