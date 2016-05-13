class EnhancersController < ApplicationController
    include ConvertInputToGene

    def index
        Enhancer.delete_all
        init_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        enhancer = Enhancer.where(name: enhancer_params[:name]).first

        if params[:commit] == "Reset"
            data = ""
        else
            gene_parser = ConvertInputToGene::ParseGene.new(enhancer_params)
            gene_parser.get_records.each do |line, sequence|
                record = Record.new(data: sequence, line: line)
                enhancer.records.push(record)
            end
            data = enhancer.records.any? ? enhancer.records.first.data : ""
            flash[:error] = gene_parser.error
        end
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
        # INFO: file is a temporary parameter only. it's not part of the model!
        params.require(:enhancer).permit(:data, :name, :file)
    end
end
