module GeneToFasta

    extend self

    def formatting(description, sequence)
        str = ">#{description}\n"
        str += split_sequence_to_fasta_lines(sequence)
    end

    def split_sequence_to_fasta_lines(sequence)
        sequence.scan(/.{1,80}/).join("\n")
    end
end