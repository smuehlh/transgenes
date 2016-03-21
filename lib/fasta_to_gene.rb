require_relative 'to_gene.rb'

class FastaToGene < ToGene

    attr_reader :translations, :exons, :introns,
        :descriptions, :genestart_lines

    def initialize(path)
        @genestart_lines = []

        # keys: elements of genestart_lines
        @translations = {} # will remain empty hash as file is not expected to contain translation
        @descriptions = {}
        @exons = {}
        @introns = {}

        read_file(path)
        @genestart_lines.each do |key|
            convert_exons_to_uppercase_and_introns_to_lowercase(
                @exons[key], @introns[key]
            )
        end
    end

    def self.valid_file_extensions
        [".fas", ".fa", ".fasta"]
    end

    private

    def read_file(path)
        last_seq = nil
        line_number = 0 # line number in human readalbe format
        @current_genestart_line = nil

        IO.foreach(path) do |line|
            line = line.chomp
            line_number += 1
            if line.start_with?(">")
                init_class_variables_for_given_genestart_line(line_number)
                last_seq = nil

                str_wo_leading_char = line.sub(">", "")
                @descriptions[@current_genestart_line] = str_wo_leading_char
            else
                sequences = split_into_upper_and_lower_case(line)
                sequences.each do |seq|
                    if seq.is_upper?
                        @exons[@current_genestart_line].push(
                            if last_seq && last_seq.is_upper?
                                @exons[@current_genestart_line].pop + seq
                            else
                                seq
                            end
                        )
                    else
                        @introns[@current_genestart_line].push(
                            if last_seq && last_seq.is_lower?
                                @introns[@current_genestart_line].pop + seq
                            else
                                seq
                            end
                        )
                    end
                    last_seq = seq
                end
            end
        end
    end

    def split_into_upper_and_lower_case(str)
        parts = []
        last_char = nil
        str.each_char do |char|
            parts.push(
                if char.is_upper?
                    if last_char && last_char.is_upper?
                        parts.pop + char
                    else
                        char
                    end
                else
                    if last_char && last_char.is_lower?
                        parts.pop + char
                    else
                        char
                    end
                end
            )
            last_char = char
        end
        parts
    end

    def init_class_variables_for_given_genestart_line(line_number)
        @current_genestart_line = line_number
        @genestart_lines.push @current_genestart_line
        @descriptions[@current_genestart_line] = ""
        @exons[@current_genestart_line] = []
        @introns[@current_genestart_line] = []
    end
end