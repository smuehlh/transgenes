class Record < ActiveRecord::Base
    belongs_to :enhancer

    serialize :exons
    serialize :introns
end
