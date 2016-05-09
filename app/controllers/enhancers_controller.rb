class EnhancersController < ApplicationController
    include ConvertInputToGene

    def index
        Enhancer.delete_all
        init_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        if params[:commit] == "Reset"
            data = ""
        else
            gene_parser = ConvertInputToGene::ParseGene.new(
                params.require(:enhancer)
            )
            flash[:error] = gene_parser.error
            data = gene_parser.get_sequence # parse first record by default
            @is_first_record_of_multiple = gene_parser.is_multiple_records
        end
        enhancer = Enhancer.where(name: enhancer_params[:name]).first
        enhancer.update_attributes(data: data)
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
    end

    private

    def init_gene_enhancers
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
        params.require(:enhancer).permit(:data, :name)
    end
end
