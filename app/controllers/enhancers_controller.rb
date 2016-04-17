class EnhancersController < ApplicationController

    def index
        Enhancer.delete_all
        init_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        # INFO: do not change the order of resources
        enhancer = Enhancer.where(name: enhancer_params[:name]).first
        if params[:commit] == "Reset"
            enhancer.update_attributes(data: "")
        else
            enhancer.update_attributes(enhancer_params)
        end
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
