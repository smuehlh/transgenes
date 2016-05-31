class RecordsChangeColumnType < ActiveRecord::Migration
    def change
        change_column(:records, :data, :text)
    end
end
