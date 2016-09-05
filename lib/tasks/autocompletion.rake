namespace :autocompletion do

    desc "Update (= delete and setup) Ensemble Gene Ids for autocompletion"
    task :update => [:delete, :setup] do
        puts "All done."
    end

    desc "Delete Ensemble Gene Id autocompletion records"
    task delete: :environment do
        # EnsembleGene.delete_all
        puts "Deleted EnsembleGene records"
    end

    desc "Setup Ensemble Gene Id autocompletion records"
    task setup: :environment do
        require File.join(Rails.root, 'lib', 'build_ensemble_autocompletion_index', 'get_ensemble_data.rb')
        GetEnsembleData.new
        puts "Downloaded new EnsembleGenes."
    end
end
