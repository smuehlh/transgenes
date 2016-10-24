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
            require path_to_ensembl_client_lib
            parse_download(path_to_newest_ensembl_download)
        end

        def parse_download(file)
            return unless file
            entry = ""
            IO.foreach(file) do |line|
                if line_starts_new_gene_entry?(entry, line)
                    # import previous entry
                    import_gene_entry(entry)
                    # start new entry
                    entry = ""
                end
                entry += line
            end
            # import previous entry
            import_gene_entry(entry)
        end

        def line_starts_new_gene_entry?(entry, line)
            # only true if entry exists and starts with diff. entry
            ! entry.empty? && line.start_with?(">") && GetEnsemblData.split_fasta_header(entry.lines[0])[0] != GetEnsemblData.split_fasta_header(line)[0]
        end

        def import_gene_entry(entry)
            utr5, cds, utr3 = "", "", ""
            geneid, release = "", ""

            parts = entry.split(/(?=\>)/)
            parts.each do |subentry|
                header = subentry.lines[0]
                seq = subentry.lines[1..-1].collect(&:strip).join("")
                geneid, kind, release = GetEnsemblData.split_fasta_header(header)
                if kind == "CDS"
                    cds = seq
                elsif kind == "5'UTR"
                    utr5 = seq
                else
                    utr3 = seq
                end
            end
            EnsemblGene.import(geneid, cds, utr5, utr3, release)
        end
    end
end