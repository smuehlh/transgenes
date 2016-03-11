require_relative 'to_gene.rb'

class GenebankToGene < ToGene

    attr_reader :translation, :description, :exons, :introns

    def initialize(path)
        @translation = ""
        @description = ""
        @exons = []
        @introns = []

        read_file(path)
        @exons = convert_to_uppercase(@exons)

        ensure_exon_translation_matches_given_translation(@exons, translation)
    end

    private

    def read_file(path)
        @field = ""
        @gene_info_field = ""
        @gene_info_coding_seq_field = ""

        gene_sequence = ""
        exon_positions = []

        IO.foreach(path) do |line|
            # detect with information is contained in this line
            update_current_fields(line)

            # update results variables as appropriate
            @description = get_gene_description(line) if is_gene_description_field

            @translation = get_translation(line) if is_gene_translation_field

            exon_positions = get_exon_positions(line) if is_gene_positions_field

            gene_sequence += get_gene_sequence(line) if is_sequence_field
        end

        cut_gene_sequence_into_exons_and_introns(gene_sequence, exon_positions)
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
        /CDS\s+(join\()?\d\)?/
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
        # HACK
        # gene position identifier deletes first digit -- add it back!
        first_digit = line[/\d/]
        positions = line.regexp_delete(coding_sequence_exon_position_identifier)
        positions = first_digit + positions.delete("\)").strip
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
            \w+         # any word character
            /x
        line[regexp]
    end

    def is_line_contains_new_gene_info_coding_seq_entry(line)
        line[gene_info_coding_seq_identifier]
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

    def convert_positions_string_to_array_of_integers(str)
        str.split(",").map do |range|
            range.split("..").map{|pos| Counting.human_to_ruby(pos.to_i)}
        end
    end

    def cut_gene_sequence_into_exons_and_introns(sequence, exon_positions)
        last_exon_stop = nil
        exon_positions.each do |exon_start, exon_stop|
            # preceeding intron - all but the very first exon have one
            if last_exon_stop
                intron_start = last_exon_stop + 1
                intron_stop = exon_start - 1
                @introns.push(sequence[intron_start..intron_stop])
            end
            # exon
            @exons.push(sequence[exon_start..exon_stop])
            last_exon_stop = exon_stop
        end
    end
end