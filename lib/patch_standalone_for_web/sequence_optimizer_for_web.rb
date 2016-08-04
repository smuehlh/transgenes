module SequenceOptimizerForWeb

    extend self

    def tweak_gene(web_genes, web_params)
        options = WebinputToOptions.new(web_params)
        gene = init_gene_obj(web_genes)
        log = tweak_gene_verbosely(gene, options)

        info = combine_info_about_tweaked_gene(log, options)
        gene, info
    end

    private

    def init_gene_obj(web_genes)
        gene = Gene.new
        gene.add_cds(*web_genes[:cds]) if web_genes[:cds]
        gene.add_five_prime_utr(*web_genes[:five_utr]) if web_genes[:five_utr]
        gene.add_three_prime_utr(*web_genes[:three_utr]) if web_genes[:three_utr]
        gene
    end

    def tweak_gene_verbosely(gene, options)
        CoreExtensions::Settings.setup

        gene.remove_introns(options.remove_first_intron)
        gene.tweak_sequence(options.strategy)
        gene.log_tweak_statistics

        CoreExtensions::Settings.get_log_content
    end

    def combine_info_about_tweaked_gene(log, options)
        Info = Struct.new(:log, :strategy, :keep_first_intron)
        Info.new(log, options.strategy, options.keep_first_intron)
    end
end