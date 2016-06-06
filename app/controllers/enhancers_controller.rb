class EnhancersController < ApplicationController

    def index
        flash.clear
        delete_old_init_new_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
        @enhancer = Enhancer.new
    end

    def create
        @enhancer = Enhancer.where(name: enhancer_params[:name]).first
        reset_active_enhancer_and_associated_records
        update_active_enhancer if enhancer_params[:commit] == "Save"
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

    def reset_active_enhancer_and_associated_records
        # records associated with previous input (if any) are invalid.
        @enhancer.reset
        @enhancer.records.delete_all
        flash.delete(:error)
    end

    def update_active_enhancer
        gene_parser = WebinputToGene.new(enhancer_params,remotipart_submitted?)
        gene_parser.get_records.each do |line, gene_record|
            record = Record.new(
                data: gene_record[:sequence],
                line: line,
                exons: gene_record[:exons],
                introns: gene_record[:introns]
                )
            @enhancer.records.push(record)

            @enhancer.update_with_record_data(record) if is_wanted_record(record)
        end
        flash[:error] = gene_parser.error
    end

    def is_wanted_record(record)
        # use selected record (if any). default to first record.
        selected_line = record_params[:line] || @enhancer.records.first.line
        record.line == selected_line
    end

    def update_gene

    end
end
