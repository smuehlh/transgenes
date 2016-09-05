namespace :autocompletion do

    desc "Update (= delete and setup) Ensembl Gene Ids for autocompletion"
    task :update => [:delete, :setup] do
    end

    desc "Delete Ensembl Gene Id autocompletion records"
    task delete: :environment do
        EnsemblGene.delete_all
    end

    desc "Setup Ensembl Gene Id autocompletion records"
    task setup: :environment do
        require File.join(Rails.root, 'lib', 'build_ensembl_autocompletion_index', 'get_ensembl_data.rb')
        ensembl_data = GetEnsemblData.new

        EnsemblGene.import(
            ensembl_data.gene_ids,
            ensembl_data.gene_seqs,
            ensembl_data.release
        )
    end
end
