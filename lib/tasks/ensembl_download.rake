namespace :ensembl do
    namespace :download do

        desc "Get Ensembl Transcripts and create tmp-file"
        task transcripts: :environment do
            require path_to_ensembl_client_lib

            client = GetEnsemblData.new
            client.get_transcripts(new_path_to_ensembl_download)
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

        def path_to_newest_ensembl_download
            path_to_ensembl_downloads.sort.reverse.first
        end

        def new_path_to_ensembl_download
            today = Time.new.strftime("%Y%m%d")
            File.join(basepath_ensembl_queries, "transcripts_#{today}.txt")
        end

        def basepath_ensembl_queries
            File.join(Rails.root, 'lib', 'build_ensembl')
        end
    end
end