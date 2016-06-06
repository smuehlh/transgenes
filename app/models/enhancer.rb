class Enhancer < ActiveRecord::Base
    has_many :records, dependent: :destroy
    validates :name, presence: true

    serialize :exons
    serialize :introns

    def reset
        self.update_attributes(data: "")
        self.update_attributes(exons: [])
        self.update_attributes(introns: [])
    end

    def update_with_record_data(record)
        self.update_attributes(data: record.data)
        self.update_attributes(exons: record.exons)
        self.update_attributes(introns: record.introns)
    end
end