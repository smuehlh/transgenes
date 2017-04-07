class SequenceOptimizerForWeb

    include CoreExtensions::FileHelper

    attr_reader :error, :stats

    def self.get_gene_statistics(web_genes)
        obj = SequenceOptimizerForWeb.new(web_genes)
        obj.stats
    end

    def initialize(web_genes, web_ese_motifs=nil)
        @error = ""
        @gene = nil
        @stats = {}
        CoreExtensions::Settings.setup_for_debugging

        init_gene_obj(web_genes, web_ese_motifs)
        init_gene_statistics
    rescue EnhancerError => exception
        @error = exception.to_s
    end

    def was_success?
        @error.blank?
    end

    private

    def init_gene_obj(web_genes, web_ese_motifs=nil)
        @gene = Gene.new
        @gene.add_cds(*web_genes[:cds]) if web_genes[:cds]
        @gene.add_five_prime_utr(*web_genes[:five_utr]) if web_genes[:five_utr]
        @gene.add_three_prime_utr(*web_genes[:three_utr]) if web_genes[:three_utr]

        @gene.add_ese_list(web_ese_motifs) if web_ese_motifs
    rescue StandardError
        raise EnhancerError, "Cannot parse gene."
    end

    def init_gene_statistics
        overall_length = @gene.sequence.size
        introns_length = @gene.introns.join.size
        first_intron_length = ( @gene.introns.first || "").size

        @stats[:n_exons] = @gene.exons.size
        @stats[:len_wo_first_intron] = overall_length - introns_length
        @stats[:len_w_first_intron] = @stats[:len_wo_first_intron] + first_intron_length
    rescue StandardError
        raise EnhancerError, "Cannot parse gene."
    end
end