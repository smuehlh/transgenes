namespace :ensembl do
    namespace :download do

        basepath = File.join(Rails.root, 'lib', 'build_ensembl_autocompletion_index')
        require File.join(basepath, 'get_ensembl_data.rb')

        desc "Get Ensembl Transcripts"
        task transcripts: :environment do
            today = Time.new.strftime("%Y%m%d")
            file = File.join(basepath, "transcripts_#{today}.txt")
            api = GetEnsemblData.new(file)
            api.get_transcripts
        end
    end
end