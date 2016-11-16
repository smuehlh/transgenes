class Gene
    attr_reader :exons, :introns, :ese_motifs, :five_prime_utr, :three_prime_utr, :description

    def initialize
        @description = ""
        @exons = [] # CDS only, excluding UTR's
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @ese_motifs = []
        @number_of_changed_sites = 0
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

    def add_ese_list(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def remove_introns(is_remove_first_intron)
        @introns = is_remove_first_intron ? [] : [@introns.first]
    end

    def log_statistics
        str = "Number of exons: #{@exons.size}\n"
        first_intron_kept = @introns.size == 1
        str += "All introns " + (first_intron_kept ? "but" : "including") + " the first removed.\n"
        n_aa = cds.size / 3
        str += "Number of amino acids: #{n_aa}\n"
        str += "Total mRNA size: #{sequence.size}"
        $logger.info(str)
    end

    def tweak_sequence(strategy, stay_in_subbox_for_6folds)
        scorer = ScoreSynonymousCodons.new(strategy, stay_in_subbox_for_6folds, @ese_motifs, @exons, @introns)

        scorer.synonymous_sites_in_cds.each do |pos|
            codon = scorer.select_synonymous_codon_at(pos)

            if ! scorer.is_original_codon_selected_at(pos, codon)
                replace_codon_at_pos(pos, codon)
                log_codon_replacement(scorer.log_selected_codon_at(pos, codon))
            end
        end
    end

    def log_tweak_statistics
        $logger.info("Changed #{@number_of_changed_sites} synonymous sites.")
        ErrorHandling.warn_with_error_message(
            "no_codons_replaced", "Gene"
        ) if @number_of_changed_sites == 0
    end

    def sequence
        @five_prime_utr + combine_exons_and_introns(@exons, @introns) + @three_prime_utr
    end

    private

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def cds
        @exons.join("")
    end

    def replace_codon_at_pos(third_site, new_codon)
        replace_nt_at_pos(third_site-2, new_codon[0])
        replace_nt_at_pos(third_site-1, new_codon[1])
        replace_nt_at_pos(third_site, new_codon[2])
    end

    def replace_nt_at_pos(pos, new_nt)
        @exons.each do |exon|
            if pos >= exon.size
                pos -= exon.size
            else
                exon[pos] = new_nt
                break
            end
        end
    end

    def log_codon_replacement(log)
        @number_of_changed_sites += 1
        $logger.info(log)
    end
end