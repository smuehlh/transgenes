class EnhancersController < ApplicationController

    def index
        flash.clear
        reset_session
        init_gene_enhancers
        init_ese
        init_enhanced_gene
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
    end

    def create
        flash.clear
        @enhancer = get_gene_enhancer_by_name(enhancer_params[:name])
        if enhancer_params[:commit] == "Save"
            reset_active_enhancer_and_associated_records
            update_records_associated_with_active_enhancer
            update_active_enhancer_and_generate_gene_statistics
        elsif enhancer_params[:commit] == "Line"
            update_active_enhancer_and_generate_gene_statistics
        else
            reset_active_enhancer_and_associated_records
        end
    end

    def ese
        flash.clear
        @ese = get_ese
        if ese_params[:commit] == "Save"
            update_ese
        else
            reset_ese
        end
    end

    def submit
        @enhanced_gene = get_enhanced_gene
        reset_enhanced_gene
        tweak_gene
    end

    def download
        if download_params[:fasta]
            data = get_enhanced_gene.to_fasta
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
        params.fetch(:ese).permit(:data, :file, :commit)
    end

    def enhanced_gene_params
        params.require(:enhanced_gene).permit(:strategy, :keep_first_intron, :ese)
    end

    def download_params
        params.permit(:fasta)
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

    def update_records_associated_with_active_enhancer
        gene_parser = WebinputToGene.new(enhancer_params,remotipart_submitted?)
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

        flash.now[:error] = gene_parser.error unless gene_parser.error.blank?
    end

    def update_active_enhancer_and_generate_gene_statistics
        if record = get_wanted_record
            @enhancer.update_with_record_data(record)
            generate_gene_statistics

            flash.now[:success] = true
        end
    end

    def update_ese
        ese_parser = WebinputToEse.new(ese_params,remotipart_submitted?)
        list = ese_parser.get_ese_motifs
        if ese_parser.error.blank?
            @ese.update_attribute(:data, list)
            flash.now[:success] = true
        else
            flash.now[:error] = ese_parser.error
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

    def generate_gene_statistics
        stats = SequenceOptimizerForWeb.gene_statistics(prepare_gene_enhancers_for_sequence_optimizer
        )
        uploaded_resources = get_gene_enhancers.collect{|e| e.name if e.data}.compact

        @statistics = {
            n_exons: stats.n_exons,
            uploaded_resources: uploaded_resources,
            size_w_first_intron: stats.len_w_first_intron,
            size_wo_first_intron: stats.len_wo_first_intron
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
        gene, info = SequenceOptimizerForWeb.tweak_gene(
            prepare_gene_enhancers_for_sequence_optimizer,
            prepare_ese_motifs_for_sequence_optimizer,
            enhanced_gene_params
        )
        @enhanced_gene.update_attributes(
            gene_name: gene.description,
            data: gene.sequence,
            log: info.log,
            strategy: info.strategy,
            keep_first_intron: info.keep_first_intron,
            destroy_ese_motifs: gene.ese_motifs.any?
        )
    end
end
