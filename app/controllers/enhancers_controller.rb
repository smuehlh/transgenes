class EnhancersController < ApplicationController

    def index
        flash.clear
        delete_old_init_new_gene_enhancers
        @five_enhancer, @cds_enhancer, @three_enhancer = get_gene_enhancers
    end

    def create
        @enhancer = Enhancer.where(name: enhancer_params[:name]).first
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

    def submit
        gene = tweak_gene(submit_params)
        @description, @sequence, @fasta = output_gene(gene)
    end

    def download
        data = "test"
        filename = Dir::Tmpname.make_tmpname ["gene",".fas"], nil
        send_data(data, :type => 'text/plain', :filename => filename)
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

    def submit_params
        params.require(:submit).permit(:strategy, :keep_first_intron)
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
        flash.now[:error] = gene_parser.error
    end

    def update_active_enhancer_and_generate_gene_statistics
        if record = get_wanted_record
            @enhancer.update_with_record_data(record)
            generate_gene_statistics
        end
    end

    def get_wanted_record
        # use selected record (if any). default to first record.
        if @selected_line = record_params[:line]
            # class variable needed for view
            @enhancer.records.where(line: @selected_line).first
        else
            @enhancer.records.first
        end
    end

    def generate_gene_statistics
        gene = init_gene

        # generate statistics with first intron kept
        gene.remove_introns(is_remove_first_intron = false)
        @statistics = {
            n_exons: gene.exons.size,
            sequence_length_with_first_intron: gene.sequence.size
        }

        # ... and first first intron removed
        gene.remove_introns(is_remove_first_intron = true)
        @statistics[:sequence_length_without_first_intron] = gene.sequence.size
    end

    def init_gene
        five_enhancer, cds_enhancer, three_enhancer = get_gene_enhancers
        gene = Gene.new
        gene.add_cds(*cds_enhancer.to_gene) if cds_enhancer.data
        gene.add_five_prime_utr(*five_enhancer.to_gene) if five_enhancer.data
        gene.add_three_prime_utr(*three_enhancer.to_gene) if three_enhancer.data
        gene
    end

    def tweak_gene(submit_params)
        options = WebinputToOptions.new(submit_params)
        gene = init_gene
        gene.remove_introns(options.remove_first_intron)
        gene.tweak_sequence(options.strategy)

        gene
    end

    def output_gene(gene)
        fasta = GeneToFasta.new(gene.description, gene.sequence)
        [fasta.header, fasta.sequence, fasta.fasta]
    end
end
