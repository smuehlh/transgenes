class GeneToFasta
    attr_reader :header, :sequence, :fasta

    def self.write(file, gene_obj)
        fasta_obj = GeneToFasta.new(gene_obj.description, gene_obj.sequence)
        fasta_obj.write(file)
    end

    def initialize(description, sequence, is_split_seq_at_80_chars=true)
        @header = str_to_fasta_header(description)
        @sequence = sequence
        split_sequence_to_fasta_lines if is_split_seq_at_80_chars

        @fasta = "#{@header}\n#{@sequence}"
    end

    def write(file)
        FileHelper.write_to_file(file, @fasta)
    end

    private

    def str_to_fasta_header(str)
        ">#{str}"
    end

    def split_sequence_to_fasta_lines
        @sequence = @sequence.scan(/.{1,80}/).join("\n")
    end
end