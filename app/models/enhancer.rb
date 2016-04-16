class Enhancer < ActiveRecord::Base
    validates :data, presence: true
    validates :name, presence: true
end
