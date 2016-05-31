module ExonsAndIntrons
    extend ActiveSupport::Concern

    def save_exons(exons)
        self.update_attributes(exons: arr_to_db(exons))
    end

    def save_introns(introns)
        self.update_attributes(introns: arr_to_db(introns))
    end

    def get_exons
        db_to_arr(self.exons)
    end

    def get_introns
        db_to_arr(self.introns)
    end

    private
    def arr_to_db(arr)
        arr.join(",")
    end

    def db_to_arr(str)
        str.split(",")
    end
end