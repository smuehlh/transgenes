class EnhancersController < ApplicationController
    include ConvertInputToGene

    def index
        flash.clear
        delete_old_init_new_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        @enhancer = Enhancer.where(name: enhancer_params[:name]).first
        reset_enhancer_data_and_records
        update_enhancer_data if enhancer_params[:commit] == "Save"
        # else: nothing to do. enhancer was just resetted.
    end

    def submit

    end

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
        # INFO: parameters not part of the model:
        # file, commit
        params.require(:enhancer).permit(:data, :name, :file, :commit)
    end

    def record_params
        # INFO: records might not be initialized: use fetch instead of require.
        params.fetch(:records, {}).permit(:line)
    end

    def delete_old_init_new_gene_enhancers
        Enhancer.delete_all
        Record.delete_all
        # order does matter!
        Enhancer.create(name: "5'UTR")
        Enhancer.create(name: "CDS")
        Enhancer.create(name: "3'UTR")
    end

    def get_gene_enhancers
        [
            Enhancer.where(name: "5'UTR").first,
            Enhancer.where(name: "CDS").first,
            Enhancer.where(name: "3'UTR").first
        ]
    end

    def reset_enhancer_data_and_records
        # records associated with previous input (if any) are invalid.
        @enhancer.reset_all_sequence_data
        flash.delete(:error)
    end

    def update_enhancer_data
        gene_parser = ConvertInputToGene::ParseGene.new(
            enhancer_params, remotipart_submitted?)
        gene_parser.get_records.each do |line, sequence|
            @enhancer.records.push( Record.new(data: sequence, line: line) )
        end
        if @enhancer.records.any?
            using_record = wanted_record_or_first_record
            @enhancer.set_all_sequence_data(using_record)
        end
        flash[:error] = gene_parser.error
    end

    def wanted_record_or_first_record
        if @using_line = record_params[:line]
            @enhancer.records.where(line: @using_line).first
        else
            @enhancer.records.first
        end
    end
end
