class Enhancer < ActiveRecord::Base
    has_many :records, dependent: :destroy
    validates :name, presence: true

    def reset_all_sequence_data
        self.records.delete_all
        self.update_attributes(data: "")
        self.update_attributes(exons: "")
        self.update_attributes(introns: "")
    end

    def set_all_sequence_data(record)
        self.update_attributes(data: record.data)
        self.update_attributes(exons: record.exons)
        self.update_attributes(introns: record.introns)
    end
end