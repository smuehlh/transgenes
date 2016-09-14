class WebinputToGene
    ToGene.extend CoreExtensions::FileParsing
    ToGene.include CoreExtensions::FileParsing
    include CoreExtensions::FileHelper

    attr_reader :error

    def initialize(enhancer_params, is_fileupload_input)
        @error = "" # NOTE: use @error instead of log-content to customize error messages.
        @gene_records = {}
        CoreExtensions::Settings.setup

        feature_type = enhancer_params[:name]
        file = get_fileupload_path_or_save_textinput_to_file(
            enhancer_params, is_fileupload_input)

        parse_file_and_get_gene_records(feature_type, file)
        delete_temp_file(file)

    rescue EnhancerError => exception
        @error = exception.to_s
    end

    def get_records
        @gene_records.any? ? @gene_records : {}
    end

    private

    def get_fileupload_path_or_save_textinput_to_file(params, is_fileupload_input)
        if is_fileupload_input
            params[:file].path
        else
            # textinput
            data =
                if is_ensembl_input(params[:ensembl])
                    get_ensembl_gene(params[:ensembl])
                else
                    params[:data]
                end
            base =  "gene"
            ext = get_file_extension_matching_input_type(data)
            write_to_temp_file(base, ext, data)
        end
    end

    def is_ensembl_input(geneid)
        geneid && ! geneid.blank?
    end

    def get_ensembl_gene(geneid)
        gene = EnsemblGene.where("gene_id = ?", geneid).first
        raise EnhancerError, "Invalid Ensembl gene ID provided." unless gene

        gene.to_fasta
    end

    def get_file_extension_matching_input_type(data)
        if data.start_with?(">")
            # (might be) fasta input.
            ".fas"
        elsif data.start_with?("LOCUS")
            # (might be) genebank input.
            ".gb"
        else
            # unknown input.
            ".unknown"
        end
    end

    def parse_file_and_get_gene_records(feature_type, file)
        feature_starts = get_first_feature_starts_and_warn_if_max_num_is_exceeded(
                feature_type, file
            )
        feature_starts.each do |line, teaser|
            gene = Gene.new
            begin
                gene.add_cds(*ToGene.init_and_parse(feature_type, file, line))
            rescue EnhancerError => exception
                msg = exception.to_s
                msg = "Cannot parse gene record (#{teaser}): #{msg}" if feature_starts.size > 1
                append_to_error(msg)
                next
            end
            @gene_records[line] = {
                exons: gene.exons,
                introns: gene.introns,
                sequence: gene.sequence,
                description: gene.description
            }
        end
    end

    def get_first_feature_starts_and_warn_if_max_num_is_exceeded(feature_type, file)
        max_num = 10
        feature_starts = ToGene.get_all_feature_starts(feature_type, file)
        if feature_starts.size > max_num
            append_to_error(
                "Found too many gene records. Only the first #{max_num} have been parsed."
            )
        end
        feature_starts.first(max_num).to_h
    end

    def append_to_error(msg)
        @error = @error.blank? ? msg : "#{@error}\n#{msg}"
    end
end