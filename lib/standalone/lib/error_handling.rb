class EnhancerError < StandardError
end

module ErrorHandling

    extend self

    def is_commandline_tool
        @is_commandline_tool
    end

    def is_commandline_tool=(bool)
        @is_commandline_tool = bool
    end

    def error_message_with_reference_to_commandline_option_help(str = "")
        help_ref = "Add --help to program call to view all options and their arguments."
        str == "" ? help_ref : "#{str}\n#{help_ref}"
    end

    def error_message_with_reference_to_valid_gene_starts(type, str)
        "#{type} gene start specified.\nSpecify one of the following genes using argument --line <starting-line>:\n#{str}"
    end

    def warning_message(str)
        "Warning: #{str}"
    end

    def error_code_to_webserver_error_message(code)
        case code
        when "invalid_file_format"
            "Unrecognized format. Input has to be either a GeneBank record or a FASTA file. Also, it has to specify the requested gene record."
        when "invalid_codons"
            "Found invalid codon(s)"
        when "invalid_ese_format"
            "Unrecognized format. Input has to contain ESE motifs only, one per line."
        else
            "Something went wrong."
        end
    end

    def error_code_to_commandline_error_message(code, additional_error_message = "")
        case code
        when "argument_error"
            error_message_with_reference_to_commandline_option_help(additional_error_message
            )
        when "missing_mandatory_argument"
            error_message_with_reference_to_commandline_option_help(
                "Missing mandatory option: #{additional_error_message}."
            )
        when "invalid_file_format"
            "Unrecognized file format or feature: #{additional_error_message}.\nInput has to be either a GeneBank record or a FASTA file. Also, it has to specify the requested gene record."
        when "invalid_gene_start"
            error_message_with_reference_to_valid_gene_starts(
                "Invalid", additional_error_message
            )
        when "missing_gene_start"
            error_message_with_reference_to_valid_gene_starts(
                "No", additional_error_message
            )
        when "invalid_codons"
            "Invalid codons: #{additional_error_message}"
        when "invalid_ese_format"
            "Unrecognized file format: #{additional_error_message}.\nInput has to contain ESE motifs only, one per line."
        else
            "An unknown error occured."
        end
    end

    def error_code_to_commandline_warning_message(code, additional_warning_message = "")
        case code
        when "partial_gene"
            warning_message("Gene is partial.")
        when "unused_utr_line"
            warning_message("#{additional_warning_message}: A starting line but no file was provided. Will ignore starting line.")
        end
    end

    def abort_with_error_message(code, additional_error_message = "")
        if is_commandline_tool
            abort error_code_to_commandline_error_message(
                code, additional_error_message
            )
        else
            raise EnhancerError, error_code_to_webserver_error_message(code)
        end
    end

    def warn_with_error_message(code, additional_warning_message = "")
        if is_commandline_tool
            warn error_code_to_commandline_warning_message(
                code, additional_warning_message
            )
        else
            # TODO
            # webserver
        end
    end
end