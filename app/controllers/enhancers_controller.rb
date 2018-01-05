class EnhancersController < ApplicationController

    def index
        flash.clear
        reset_session
        init_gene_enhancers
        init_ese
        init_restriction_enzyme
        init_enhanced_gene
    end

    def create_enhancer
        flash.clear
        @enhancer = get_gene_enhancer_by_name(enhancer_params[:name])
        if enhancer_params[:commit] == "Save"
            reset_active_enhancer_and_associated_records
            update_records_associated_with_active_enhancer
            update_active_enhancer
        elsif enhancer_params[:commit] == "Line"
            update_active_enhancer
        else
            reset_active_enhancer_and_associated_records
        end
        @statistics = update_statistics
    end

    def create_ese
        flash.clear
        @ese = get_ese
        if ese_params[:commit] == "Save"
            update_ese
        else
            reset_ese
        end
        @statistics = update_statistics
    end

    def create_restriction_site
        flash.clear
        @restriction_enzyme = get_restriction_enzyme
        if restriction_enzyme_params[:commit] == "Save"
            update_restriction_enzyme
        else
            reset_restriction_enzyme
        end
        @statistics = update_statistics
    end

    def submit
        flash.clear
        @enhanced_gene = get_enhanced_gene
        reset_enhanced_gene
        tweak_gene
    end

    def download
        if download_params[:kind] == "enhanced_gene"
            data = get_enhanced_gene.to_fasta
            filename = Dir::Tmpname.make_tmpname ["gene",".fas"], nil
        elsif download_params[:kind] == "gene_variants"
            data = get_enhanced_gene.fasta_formatted_synonymous_variants
            filename = Dir::Tmpname.make_tmpname ["gene",".fas"], nil
        else
            data = get_enhanced_gene.log
            filename = Dir::Tmpname.make_tmpname ["gene",".log"], nil
        end
        send_data(data, :type => 'text/plain', :filename => filename)
    end

    def ensembl_autocomplete
        # return gene_ids of first 10 matches
        suggestions = EnsemblGene.where("gene_id LIKE ?", "#{autocomplete_params[:query]}%").limit(10).pluck(:gene_id)
        render json: suggestions
    end

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
        # INFO: parameters not part of the model:
        # file, commit, ensembl
        params.require(:enhancer).permit(:data, :name, :file, :commit).merge(ensembl: ensembl_params[:gene_id])
    end

    def record_params
        # INFO: records might not be initialized: use fetch instead of require.
        params.fetch(:records, {}).permit(:line)
    end

    def ese_params
        params.fetch(:ese).permit(:data, :file, :dataset, :commit)
    end

    def restriction_enzyme_params
        params.fetch(:restriction_enzyme).permit(:to_keep, :to_avoid, :commit, :file)
    end

    def enhanced_gene_params
        params.require(:enhanced_gene).permit(:strategy, :select_by, :keep_first_intron, :ese, :ese_strategy, :stay_in_subbox, :score_eses_at_all_sites)
    end

    def download_params
        params.permit(:kind)
    end

    def autocomplete_params
        params.permit(:query)
    end

    def ensembl_params
        params.fetch(:ensembl, {}).permit(:gene_id)
    end

    def init_gene_enhancers
        # order does matter!
        Enhancer.create(name: "5'UTR", session_id: session.id)
        Enhancer.create(name: "CDS", session_id: session.id)
        Enhancer.create(name: "3'UTR", session_id: session.id)
    end

    def init_ese
        Ese.create(session_id: session.id)
    end

    def init_restriction_enzyme
        RestrictionEnzyme.create(session_id: session.id)
    end

    def init_enhanced_gene
        EnhancedGene.create(session_id: session.id)
    end

    def get_gene_enhancers
        [
            get_gene_enhancer_by_name("5'UTR"),
            get_gene_enhancer_by_name("CDS"),
            get_gene_enhancer_by_name("3'UTR")
        ]
    end

    def get_gene_enhancer_by_name(name)
        Enhancer.where("session_id = ? AND name = ?", session.id, name).first
    end

    def get_ese
        Ese.where("session_id = ?", session.id).first
    end

    def get_restriction_enzyme
        RestrictionEnzyme.where("session_id = ?", session.id).first
    end

    def get_enhanced_gene
        EnhancedGene.where("session_id = ?", session.id).first
    end

    def reset_active_enhancer_and_associated_records
        # records associated with previous input (if any) are invalid.
        @enhancer.reset
        @enhancer.records.delete_all
    end

    def reset_enhanced_gene
        @enhanced_gene.reset
    end

    def reset_ese
        @ese.reset
    end

    def reset_restriction_enzyme
        @restriction_enzyme.reset
    end

    def update_records_associated_with_active_enhancer
        gene_parser = WebinputToGene.new(enhancer_params,remotipart_submitted?)
        if gene_parser.was_success?
            gene_parser.get_records.each do |line, gene_record|
                record = Record.new(
                    data: gene_record[:sequence],
                    line: line,
                    exons: gene_record[:exons],
                    introns: gene_record[:introns],
                    gene_name: gene_record[:description]
                    )
                @enhancer.records.push(record)
            end
        else
            flash.now[:error] = gene_parser.error
            flash.now[:debug_info] = gene_parser.log
        end
    end

    def update_active_enhancer
        if record = get_wanted_record
            @enhancer.update_with_record_data(record)
            flash.now[:success] = true
        end
    end

    def update_ese
        ese_parser = WebinputToEse.new(ese_params,remotipart_submitted?)
        list = ese_parser.get_ese_motifs
        if ese_parser.was_success?
            @ese.update_attribute(:data, list)
            flash.now[:success] = true
        else
            flash.now[:error] = ese_parser.error
            flash.now[:debug_info] = ese_parser.log
        end
    end

    def update_restriction_enzyme
        enzyme_parser = WebinputToRestrictionEnzyme.new(restriction_enzyme_params,remotipart_submitted?)
        list = enzyme_parser.get_motifs
        if enzyme_parser.was_success?
            if restriction_enzyme_params[:to_keep]
                @restriction_enzyme.update_attribute(:to_keep, list)
            else
                @restriction_enzyme.update_attribute(:to_avoid, list)
            end
            flash.now[:success] = true
        else
            flash.now[:error] = enzyme_parser.error
            flash.now[:debug_info] = enzyme_parser.log
        end
    end

    def get_wanted_record
        # use selected record (if any). default to first record.
        if @selected_line = record_params[:line]
            # class variable '@selected_line' needed for view
            @enhancer.records.where("line = ?", @selected_line).first
        else
            @enhancer.records.first
        end
    end

    def update_statistics
        [
            get_gene_statistics,
            get_ese_statistics,
            get_restriction_enzyme_statistics
        ].inject(&:merge)
    end

    def get_gene_statistics
        stats = SequenceOptimizerForWeb.get_gene_statistics(prepare_gene_enhancers_for_sequence_optimizer)
        uploads = get_gene_enhancers.collect{|e| e.name if e.data}.compact

        {
            n_exons: stats[:n_exons],
            uploaded_resources: uploads,
            size_w_first_intron: stats[:len_w_first_intron],
            size_wo_first_intron: stats[:len_wo_first_intron]
        }
    end

    def get_ese_statistics
        ese = get_ese
        {
            ese_motifs: ! ese.data.blank?
        }
    end

    def get_restriction_enzyme_statistics
        restriction_enzyme = get_restriction_enzyme
        {
            sites_to_avoid: ! restriction_enzyme.to_avoid.blank?,
            sites_to_keep: ! restriction_enzyme.to_keep.blank?
        }
    end

    def prepare_gene_enhancers_for_sequence_optimizer
        five_enhancer, cds_enhancer, three_enhancer = get_gene_enhancers
        {
            five_utr: five_enhancer.data ? five_enhancer.to_gene : nil,
            cds: cds_enhancer.data ? cds_enhancer.to_gene : nil,
            three_utr: three_enhancer.data ? three_enhancer.to_gene : nil
        }
    end

    def prepare_ese_motifs_for_sequence_optimizer
        ese = get_ese
        ese.data
    end

    def tweak_gene
        optimizer = SequenceOptimizerForWeb.init_and_tweak_gene(
            prepare_gene_enhancers_for_sequence_optimizer,
            prepare_ese_motifs_for_sequence_optimizer,
            enhanced_gene_params
        )
        if optimizer.was_success?
            gene, variants, overall_gc3 = optimizer.get_tweaked_gene
            options = optimizer.get_options

            @enhanced_gene.update_attributes(
                gene_name: gene.description,
                data: gene.sequence,
                gene_variants: variants,
                gc3_over_all_gene_variants: overall_gc3,
                log: optimizer.log,
                strategy: options.strategy,
                keep_first_intron: options.is_keep_first_intron,
                select_by: options.select_by,
                stay_in_subbox_for_6folds: options.stay_in_subbox_for_6folds,
                destroy_ese_motifs: gene.ese_motifs.any?,
                ese_strategy: options.ese_strategy,
                score_eses_at_all_sites: options.score_eses_at_all_sites
            )
        else
            flash.now[:error] = optimizer.error.to_s
        end
    end
end