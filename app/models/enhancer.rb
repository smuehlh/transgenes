class Enhancer < ActiveRecord::Base
    has_many :records, dependent: :destroy
    validates :name, presence: true

    serialize :exons
    serialize :introns

    def reset
        self.update_attributes(
            data: "",
            exons: [],
            introns: [],
            gene_name: ""
        )
    end

    def update_with_record_data(record)
        self.update_attributes(
            data: record.data,
            exons: record.exons,
            introns: record.introns,
            gene_name: record.gene_name
        )
    end

    def to_gene
        [self.exons, self.introns, self.gene_name]
    end
end