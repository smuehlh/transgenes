module GeneToFasta

    extend self

    def write(file, gene_obj)
        data = formatting(gene_obj)
        FileHelper.write_to_file(file, data)
    end

    def formatting(gene_obj)
        str = ">#{gene_obj.description}\n"
        str += split_sequence_to_fasta_lines(gene_obj.sequence)
    end

    def split_sequence_to_fasta_lines(sequence)
        sequence.scan(/.{1,80}/).join("\n")
    end
end