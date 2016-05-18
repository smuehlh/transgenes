class EnhancersController < ApplicationController
    include ConvertInputToGene

    def index
        delete_old_init_new_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        @enhancer = Enhancer.where(name: enhancer_params[:name]).first
        reset_enhancer_data_and_records
        if params[:commit] == "Reset"
            # nothing to do. enhancer was just resetted.
        else
            update_enhancer_data
        end
    end

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
        # INFO: file is a temporary parameter only. it's not part of the model!
        params.require(:enhancer).permit(:data, :name, :file)
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
        @enhancer.records.delete_all
        @enhancer.update_attributes(data: "")
    end

    def update_enhancer_data
        gene_parser = ConvertInputToGene::ParseGene.new(
            enhancer_params, remotipart_submitted?)
        gene_parser.get_records.each do |line, sequence|
            record = Record.new(data: sequence, line: line)
            @enhancer.records.push(record)
        end
        flash[:error] = gene_parser.error
        if @enhancer.records.any?
            data =
                if line = record_params[:line]
                    @enhancer.records.where(line: line).first.data
                else
                    @enhancer.records.first.data
                end
            @enhancer.update_attributes(data: data)
        end
    end
end
