class EnhancersController < ApplicationController

    def index
        flash.clear
        delete_old_init_new_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
    end

    def create
        @enhancer = Enhancer.where(name: enhancer_params[:name]).first
        reset_active_enhancer_and_associated_records
        if enhancer_params[:commit] == "Save"
            update_active_enhancer
            generate_gene_statistics
        end
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
    end

    def update_active_enhancer
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

            @enhancer.update_with_record_data(record) if is_wanted_record(record)
        end
        flash.now[:error] = gene_parser.error
        flash.now[:warning] = gene_parser.warning
    end

    def is_wanted_record(record)
        # use selected record (if any). default to first record.
        @selected_line = record_params[:line] # class variable needed for view
        record.line == @selected_line || @enhancer.records.first.line
    end

    def generate_gene_statistics
        five_enhancer, cds_enhancer, three_enhancer = get_gene_enhancers
        is_remove_first_intron = false
        gene = Gene.new
        if cds_enhancer.data
            gene.add_cds(*cds_enhancer.to_gene)
            gene.remove_introns(is_remove_first_intron)
        end
        gene.add_five_prime_utr(*five_enhancer.to_gene) if five_enhancer.data
        gene.add_three_prime_utr(*three_enhancer.to_gene) if three_enhancer.data

        @statistics = {
            n_exons: gene.exons.size,
            sequence_length_with_first_intron: gene.sequence.size
        }

        # remove first intron to generate statistics for that as well
        gene.remove_introns(! is_remove_first_intron)
        @statistics[:sequence_length_without_first_intron] = gene.sequence.size
    end
end
