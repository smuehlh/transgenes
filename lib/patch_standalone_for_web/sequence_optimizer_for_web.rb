class SequenceOptimizerForWeb

    include CoreExtensions::FileHelper

    attr_reader :error, :log, :stats

    def self.get_gene_statistics(web_genes)
        obj = SequenceOptimizerForWeb.new(web_genes)
        obj.stats
    end

    def self.init_and_tweak_gene(web_genes, web_ese_motifs, web_params)
        obj = SequenceOptimizerForWeb.new(web_genes, web_ese_motifs)
        obj.tweak_gene(web_params)

        obj
    end

    def initialize(web_genes, web_ese_motifs=nil)
        CoreExtensions::Settings.setup # NOTE: no debugging output wanted!
        @error = ""
        @log = ""
        @stats = {}

        init_gene_obj(web_genes, web_ese_motifs)
        init_gene_statistics
    rescue EnhancerError => exception
        @error = exception.to_s
    end

    def get_tweaked_gene
        # NOTE: call only if there wasn't an error
        [@enhanced_gene, @enhancer.fasta_formatted_gene_variants, @enhancer.cross_variant_gc3_per_pos]
    end

    def get_options
        # NOTE: call only if there wasn't an error
        @options
    end

    def was_success?
        @error.blank?
    end

    def tweak_gene(web_params)
        @options = WebinputToOptions.new(web_params)
        @enhancer = GeneEnhancer.new(@options.strategy, @options.select_by, @options.stay_in_subbox_for_6folds)
        @enhancer.generate_synonymous_genes(@gene)
        @enhanced_gene = @enhancer.select_best_gene

    rescue EnhancerError => exception
        @error = exception.to_s
    ensure
        @log = CoreExtensions::Settings.get_log_content
    end

    private

    def init_gene_obj(web_genes, web_ese_motifs=nil)
        @gene = Gene.new
        @gene.add_cds(*web_genes[:cds]) if web_genes[:cds]
        @gene.add_five_prime_utr(*web_genes[:five_utr]) if web_genes[:five_utr]
        @gene.add_three_prime_utr(*web_genes[:three_utr]) if web_genes[:three_utr]
        @gene.add_ese_list(web_ese_motifs) if web_ese_motifs

        @gene.remove_introns(@options.remove_first_intron) if @options
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