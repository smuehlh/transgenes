namespace :ensembl do
    namespace :download do

        basepath = File.join(Rails.root, 'lib', 'build_ensembl_autocompletion_index')
        require File.join(basepath, 'get_ensembl_data.rb')

        desc "Get Ensembl Genes"
        task genes: :environment do

        end

        desc "Get Ensembl Transcripts"
        task transcripts: :environment do
            file = File.join(basepath, "transcripts_#{DateTime.now}.txt")
            api = GetEnsemblData.new(file)
            api.get_transcripts
            # TODO: save to file!
        end
    end
end