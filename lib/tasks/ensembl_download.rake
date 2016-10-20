namespace :ensembl do
    namespace :download do

        desc "Get Ensembl Transcripts and create tmp-file"
        task transcripts: :environment do
            require path_to_ensembl_client_lib

            client = GetEnsemblData.new(new_path_to_ensembl_download)
            client.get_transcripts
        end

        desc "Clear transcripts tmp-file"
        task clear: :environment do
            FileUtils.rm path_to_ensembl_downloads
        end

        def path_to_ensembl_client_lib
            File.join(basepath_ensembl_queries, 'get_ensembl_data.rb')
        end

        def path_to_ensembl_downloads
            files = File.join(basepath_ensembl_queries, "transcripts_*")
            Dir.glob(files)
        end

        def new_path_to_ensembl_download
            today = Time.new.strftime("%Y%m%d")
            File.join(basepath_ensembl_queries, "transcripts_#{today}.txt")
        end

        def basepath_ensembl_queries
            File.join(Rails.root, 'lib', 'build_ensembl_autocompletion_index')
        end
    end
end