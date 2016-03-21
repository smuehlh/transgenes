require_relative 'to_gene.rb'

class GenebankToGene < ToGene

    attr_reader :translations, :exons, :introns,
        :descriptions, :warning_messages_if_gene_is_partial,
        :genestart_lines

    def initialize(path)
        @genestart_lines = []

        # keys: elements of genestart_lines
        @translations = {}
        @descriptions = {}
        @exons = {}
        @introns = {}
        @warning_messages_if_gene_is_partial = {}

        read_file(path)
        @genestart_lines.each do |key|
            convert_exons_to_uppercase_and_introns_to_lowercase(
                @exons[key], @introns[key]
            )
        end
    end

    def self.valid_file_extensions
        ".gb"
    end

    private

    def read_file(path)
        @field = ""
        @gene_info_field = ""
        @gene_info_coding_seq_field = ""
        @first_gene_info_coding_seq_line = nil

        @gene_sequence = "" # single gene sequence for all genes
        @exon_positions = {}
        @are_genes_on_minus_strand = {}

        line_number = 0 # line number in human readalbe format
        @current_genestart_line = nil

        IO.foreach(path) do |line|
            line_number += 1

            # detect with information is contained in this line
            update_current_fields(line)

            init_class_variables_for_given_genestart_line(line_number) if @first_gene_info_coding_seq_line

            # update results variables as appropriate
            if is_gene_positions_field
                @warning_messages_if_gene_is_partial[@current_genestart_line] = get_partial_warning_message_if_gene_is_partial(line)
                @exon_positions[@current_genestart_line] += get_exon_positions(line)
                @are_genes_on_minus_strand[@current_genestart_line] = true if is_line_contains_complementarty_coding_seq_entry(line)
            end

            if is_gene_description_field
                @descriptions[@current_genestart_line] =
                    if @descriptions[@current_genestart_line] == ""
                        get_gene_description(line)
                    else
                        "#{@descriptions[@current_genestart_line]} #{get_gene_description(line)}"
                    end
            end

            @translations[@current_genestart_line] += get_translation(line) if is_gene_translation_field

            @gene_sequence += get_gene_sequence(line) if is_sequence_field
        end

        cut_gene_sequence_into_exons_and_introns
        fix_minus_strands
    end

    # regular expressions
    def gene_info_coding_seq_identifier
        /
            ^   # match beginning of line
            #{tab_or_several_blanks_identifier} # whitespace other than newline and single blank
            (   # alternative match either
                    # standard identifier or
                    # exonpositions identifier
                #{coding_sequence_key_identifier}
            |
                #{coding_sequence_exon_position_identifier}
            )
        /x
    end

    def tab_or_several_blanks_identifier
        /[^\S\n]{2,}/
    end

    def coding_sequence_exon_position_identifier
        /CDS\s+(complement\()?(join\()?<?\d\)?\)?/
    end

    def exon_positions_on_minus_strand_identifier
        /complement\(/
    end

    def coding_sequence_key_identifier
        /\/\w+=/
    end

    def gene_description_identifier
        /\/gene=/
    end

    def gene_translation_identifier
        /\/translation=/
    end
    # end - regular expression

    def update_current_fields(line)
        @first_gene_info_coding_seq_line = false

        if is_line_contains_new_field_entry(line)
            @field = get_field(line)
            @gene_info_field = ""
            @gene_info_coding_seq_field = ""
        end

        # nested field. check for parent field as well
        if is_gene_info_field && is_line_contains_new_gene_info_entry(line)
            @gene_info_field = get_gene_info_field(line)
            @gene_info_coding_seq_field = ""
        end

        # nested field. check for parent field as well
        if is_gene_info_coding_seq_field &&
                is_line_contains_new_gene_info_coding_seq_entry(line)
            @gene_info_coding_seq_field = get_gene_info_coding_seq_field(line)
        end

        if is_gene_positions_field && is_line_contains_new_coding_seq_exon_positions_entry(line)
            @first_gene_info_coding_seq_line = true
        end
    end

    def get_field(line)
        line.split("\s")[0]
    end

    def get_gene_info_field(line)
        get_field(line.lstrip)
    end

    def get_gene_info_coding_seq_field(line)
        if line[coding_sequence_exon_position_identifier]
            # exon positions
            "exon_positions"
        else
            # standard key
            line[coding_sequence_key_identifier]
        end
    end

    def get_gene_description(line)
        gene_description =
            line.regexp_delete(gene_description_identifier)
        gene_description.delete("\"").strip
    end

    def get_translation(line)
        gene_translation = line.regexp_delete(gene_translation_identifier)
        gene_translation.delete("\"").strip
    end

    def get_exon_positions(line)
        positions =
            if line[coding_sequence_exon_position_identifier]
                # first exon-positions line contains identifier and exon-positions

                # HACK
                # gene position identifier deletes first digit -- add it back!
                first_digit = line[/\d/]
                first_digit + trim_positions_string(
                    line.regexp_delete(
                        coding_sequence_exon_position_identifier
                    )
                )
            else
                # all other lines contain only exon-positions, no additional identifiers
                trim_positions_string(line)
            end
        convert_positions_string_to_array_of_integers(positions)
    end

    def get_gene_sequence(line)
        line.regexp_delete(/ORIGIN/).regexp_delete(/[^atcg]/i)
    end

    def is_line_contains_new_field_entry(line)
        line[0].is_upper?
    end

    def is_line_contains_new_gene_info_entry(line)
        regexp = /
            ^           # match beginning of line
            #{tab_or_several_blanks_identifier} # whitespace other than newline and single blank
            [a-zA-Z]+   # character
            #{tab_or_several_blanks_identifier} # whitespace other than newline and single blank
            \S+         # any word character
            /x
        line[regexp]
    end

    def is_line_contains_new_gene_info_coding_seq_entry(line)
        line[gene_info_coding_seq_identifier]
    end

    def is_line_contains_complementarty_coding_seq_entry(line)
        line[exon_positions_on_minus_strand_identifier]
    end

    def is_line_contains_new_coding_seq_exon_positions_entry(line)
        line[coding_sequence_exon_position_identifier()]
    end

    def is_sequence_field
        @field == "ORIGIN"
    end

    def is_gene_info_field
        @field == "FEATURES"
    end

    def is_gene_info_coding_seq_field
        @gene_info_field == "CDS"
    end

    def is_gene_description_field
        @gene_info_coding_seq_field == "/gene="
    end

    def is_gene_translation_field
        @gene_info_coding_seq_field == "/translation="
    end

    def is_gene_positions_field
        @gene_info_coding_seq_field == "exon_positions"
    end

    def trim_positions_string(str)
        str.delete("\)<>").strip
    end

    def get_partial_warning_message_if_gene_is_partial(line)
        if line[/(<\d|\d<)/]
            "CDS partial on the 5' end"
        elsif line[/(\d>|>\d)/]
            "CDS partial on the 3' end"
        else
            nil
        end
    end

    def convert_positions_string_to_array_of_integers(str)
        str.split(",").map do |range|
            range.split("..").map{|pos| Counting.human_to_ruby(pos.to_i)}
        end
    end

    def cut_gene_sequence_into_exons_and_introns
        @exon_positions.each do |genestart_line, positions|
            last_exon_stop = nil
            positions.each do |exon_start, exon_stop|
                # preceeding intron - all but the very first exon have one
                if last_exon_stop
                    intron_start = last_exon_stop + 1
                    intron_stop = exon_start - 1
                    @introns[genestart_line].push(
                        @gene_sequence[intron_start..intron_stop])
                end
                # exon
                @exons[genestart_line].push(
                    @gene_sequence[exon_start..exon_stop])
                last_exon_stop = exon_stop
            end
        end
    end

    def fix_minus_strands
        @are_genes_on_minus_strand.each do |genestart_line, is_on_minus_strand|
            if is_on_minus_strand
                @exons[genestart_line] = @exons[genestart_line].reverse
                @introns[genestart_line] = @introns[genestart_line].reverse

                @exons[genestart_line] = @exons[genestart_line].map{ |e| Nucleotide.reverse_complement(e) }
                @introns[genestart_line] = @introns[genestart_line].map{ |i| Nucleotide.reverse_complement(i) }
            end
        end
    end

    def init_class_variables_for_given_genestart_line(line_number)
        @current_genestart_line = line_number
        @genestart_lines.push @current_genestart_line

        @descriptions[@current_genestart_line] = ""
        @translations[@current_genestart_line] = ""
        @exons[@current_genestart_line] = []
        @introns[@current_genestart_line] = []
        @warning_messages_if_gene_is_partial[@current_genestart_line] = ""

        @exon_positions[@current_genestart_line] = []
        @are_genes_on_minus_strand[@current_genestart_line] = false
    end
end