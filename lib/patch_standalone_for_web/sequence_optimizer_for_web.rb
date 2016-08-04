module SequenceOptimizerForWeb

    extend self

    def tweak_gene(gene, web_params)
        options = WebinputToOptions.new(web_params)
        log = tweak_gene_verbosely(gene, options)
        combine_info_about_tweaked_gene(options, log)
    end

    private

    def tweak_gene_verbosely(gene, options)
        CoreExtensions::Settings.setup

        gene.remove_introns(options.remove_first_intron)
        gene.tweak_sequence(options.strategy)
        gene.log_tweak_statistics

        CoreExtensions::Settings.get_log_content
    end

    def combine_info_about_tweaked_gene(options, log)
        {
            log: log,
            strategy: options.strategy,
            keep_first_intron: options.is_keep_first_intron
        }
    end
end