module SequenceOptimizerForWeb

    extend self

    def gene_statistics(web_genes)
        gene_w_first_intron = init_gene_obj(web_genes)
        gene_w_first_intron.remove_introns(is_remove_first_intron = false) # 1.intron kept

        gene_wo_first_intron = init_gene_obj(web_genes)
        gene_wo_first_intron.remove_introns(is_remove_first_intron = true) # 1.intron removed

        combine_info_about_gene_stats(gene_w_first_intron, gene_wo_first_intron)
    end

    def tweak_gene(web_genes, web_ese_motifs, web_params)
        options = WebinputToOptions.new(web_params)
        gene = init_gene_obj(web_genes, web_ese_motifs)
        gene.remove_introns(options.remove_first_intron)
        enhanced_gene, log = tweak_gene_verbosely(gene, options)

        info = combine_info_about_tweaked_gene(log, options)
        [enhanced_gene, info]
    end

    private

    def init_gene_obj(web_genes, web_ese_motifs=nil)
        gene = Gene.new
        gene.add_cds(*web_genes[:cds]) if web_genes[:cds]
        gene.add_five_prime_utr(*web_genes[:five_utr]) if web_genes[:five_utr]
        gene.add_three_prime_utr(*web_genes[:three_utr]) if web_genes[:three_utr]

        gene.add_ese_list(web_ese_motifs) if web_ese_motifs

        gene
    end

    def combine_info_about_gene_stats(gene_w_first_intron, gene_wo_first_intron)
        Struct.new("Info", :n_exons, :len_w_first_intron, :len_wo_first_intron)
        Struct::Info.new(
            gene_w_first_intron.exons.size,
            gene_w_first_intron.sequence.size,
            gene_wo_first_intron.sequence.size
        )
    end

    def tweak_gene_verbosely(gene, options)
        CoreExtensions::Settings.setup

        enhancer = GeneEnhancer.new(options.strategy, options.stay_in_subbox_for_6folds)
        enhancer.generate_synonymous_genes(gene)
        enhanced_gene = enhancer.select_best_gene

        log = CoreExtensions::Settings.get_log_content

        [enhanced_gene, log]
    end

    def combine_info_about_tweaked_gene(log, options)
        Struct.new("Info", :log, :strategy, :keep_first_intron)
        Struct::Info.new(log, options.strategy, options.is_keep_first_intron)
    end
end