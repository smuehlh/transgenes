class GenebankToGene

    attr_reader :translation, :description, :exons, :introns

    def initialize(path)
        @translation = ""
        @description = []
        @exons = []
        @introns = []

        @gene_description_identifier = /^\s+\/gene=/
        @gene_translation_identifier = /^\s+\/translation=/
        @gene_position_identifier = /^\s+CDS\s+(join\()?\d\)?/

        read_file(path)
    end

    private

    def read_file(path)
        current_field = ""
        current_gene_info_field = ""

        gene_sequence = ""
        exon_positions = []

        IO.foreach(path) do |line|
            # detect with information is contained in this line
            current_field = update_current_field(line) if   is_line_contains_new_field_entry(line)

            current_gene_info_field = update_current_gene_info_field(line) if is_line_contains_new_gene_info_entry(current_field, line)

#  TODO
#  gene-fields (level below CDS) can all last for several lines!!!
#  - not all translation lines are catched as it is multi-line field (same for exon-positions in fanca???)

            # update results variables as appropriate
            @description = get_description(line) if
                is_gene_description_field(
                    current_field, current_gene_info_field, line
                )

            @translation = get_translation(line) if
                is_gene_translation_field(
                    current_field, current_gene_info_field, line
                )

            exon_positions = get_exon_positions(line) if is_gene_positions_field(
                    current_field, current_gene_info_field, line
                )

            gene_sequence = update_gene_seq(gene_sequence, line) if is_sequence_field(current_field)

        end

        cut_gene_sequence_into_exons_and_introns(gene_sequence, exon_positions)
        # TODO
        # @exons mit translation vergleichen! (besser in gene.rb oder hier?)

    end

    def update_current_field(line)
        line.split("\s")[0]
    end

    def update_current_gene_info_field(line)
        update_current_field(line.lstrip)
    end

    def is_line_contains_new_field_entry(line)
        line[0].is_upper?
    end

    def is_line_contains_new_gene_info_entry(field, line)
        regexp = /
            ^           # match beginning of line
            [^\S\n]{2,} # whitespace other than newline and single blank
            [a-zA-Z]+   # character
            [^\S\n]{2,} # whitespace other than newline and single blank
            \w+         # any word character
        /x
        is_gene_info_field(field) && line[regexp]
    end

    def is_sequence_field(field)
        field == "ORIGIN"
    end

    def is_gene_info_field(field)
        field == "FEATURES"
    end

    def is_gene_coding_seq_info_field(field, gene_info_field)
        is_gene_info_field(field) && gene_info_field == "CDS"
    end

    def is_gene_description_field(field, gene_info_field, line)
        is_gene_coding_seq_info_field(field, gene_info_field) &&
        line[@gene_description_identifier]
    end

    def is_gene_positions_field(field, gene_info_field, line)
        is_gene_coding_seq_info_field(field, gene_info_field) &&
        line[@gene_position_identifier]
    end

    def is_gene_translation_field(field, gene_info_field, line)
        is_gene_coding_seq_info_field(field, gene_info_field) &&
        line[@gene_translation_identifier]
    end

    def update_gene_seq(seq, line)
        if is_line_contains_new_field_entry(line)
            seq
        else
            seq += line.regexp_delete(/[^atcg]/i)
        end
    end

    def get_description(line)
        line.regexp_delete(@gene_description_identifier).delete("\"")
    end

    def get_translation(line)
        puts line
    end

    def get_exon_positions(line)
        # HACK
        # gene position idenfier deletes first digit -- add it back!
        first_digit = line[/\d/]
        positions = first_digit + line.regexp_delete(@gene_position_identifier)
        convert_positions_string_to_array_of_integers(positions)
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