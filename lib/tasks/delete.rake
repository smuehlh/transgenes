namespace :delete do
    desc "Delete old records in enhancers, eses, enhanced_genes and records tables"
    task old_records: :environment do
        expires = 2.days.ago
        # NOTE: 'destroy' to delete all depended rows from records-table too.
        Enhancer.where("created_at < ?", expires).destroy_all
        Record.where("created_at < ?", expires).delete_all # just to make sure ...
        Ese.where("created_at < ?", expires).delete_all
        EnhancedGene.where("created_at < ?", expires).delete_all
    end
end