class EnhancedGene < ActiveRecord::Base
    serialize :gene_variants

    def reset
        self.update_attributes(
            gene_name: "",
            data: "",
            gene_variants: "",
            log: "",
            strategy: "",
            select_by: "",
            keep_first_intron: false
        )
    end

    def to_fasta(is_split_seq=true)
        to_fasta_obj = GeneToFasta.new(self.gene_name, self.data, is_split_seq)
        to_fasta_obj.fasta
    end

    def fasta_formatted_synonymous_variants
        self.gene_variants.collect.with_index do |seq, ind|
            name = "#{self.gene_name} -- Variant #{Counting.ruby_to_human(ind)}"
            to_fasta_obj = GeneToFasta.new(name, seq)
            to_fasta_obj.fasta
        end.join("\n")
    end
end