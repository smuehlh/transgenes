namespace :ensembl do
    namespace :db do

        desc "Update EnsemblGene: download transcripts, import and clean up"
        task :update => ["download:transcripts", "db:clear", "db:add", "download:clear"] do
        end

        desc "Clear records"
        task clear: :environment do
            EnsemblGene.delete_all
        end

        desc "Import transcripts from tmp-file"
        task add: :environment do
            require File.join(Rails.root, 'lib', 'build_ensembl_autocompletion_index', 'get_ensembl_data.rb')
            ensembl_data = GetEnsemblData.new

            EnsemblGene.import(
                ensembl_data.gene_ids,
                ensembl_data.gene_seqs,
                ensembl_data.release
            )
        end
    end
end