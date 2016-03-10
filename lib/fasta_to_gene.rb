class FastaToGene

    attr_reader :translation, :description, :exons, :introns

    def initialize(path)
        @description = []
        @exons = []
        @introns = []

        read_file(path)

        # exon translation is not part of file; translate them manually
        @translation = translate_exons
    end

    private

    def read_file(path)
        last_seq = nil

        IO.foreach(path) do |line|
            line = line.chomp
            if line.start_with?(">")
                str_wo_leading_char = line.sub(">", "")
                @description.push(str_wo_leading_char)
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

    def translate_exons
        joined_exons = @exons.join("")
        AminoAcid.translate(joined_exons)
    end

end