require_relative 'to_gene.rb'

class FastaToGene < ToGene

    attr_reader :translation, :exons, :introns,
        :descriptions, :genestart_lines

    def initialize(path)
        @translation = nil # exon translation is not part of file
        @descriptions = []
        @genestart_lines = []
        @exons = []
        @introns = []

        read_file(path)
        convert_exons_to_uppercase_and_introns_to_lowercase(@exons, @introns)
    end

    def self.valid_file_extensions
        [".fas", ".fa", ".fasta"]
    end

    private

    def read_file(path)
        last_seq = nil
        line_number = 0 # line number in human readalbe format

        IO.foreach(path) do |line|
            line = line.chomp
            line_number += 1
            if line.start_with?(">")
                str_wo_leading_char = line.sub(">", "")
                @descriptions.push(str_wo_leading_char)
                @genestart_lines.push(line_number)
            else
                sequences = split_into_upper_and_lower_case(line)
                sequences.each do |seq|
                    if seq.is_upper?
                        @exons.push(
                            if last_seq && last_seq.is_upper?
                                @exons.pop + seq
                            else
                                seq
                            end
                        )
                    else
                        @introns.push(
                            if last_seq && last_seq.is_lower?
                                @introns.pop + seq
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
end