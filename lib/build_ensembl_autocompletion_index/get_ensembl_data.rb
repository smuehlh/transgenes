class GetEnsemblData

    require 'net/http'
    require 'uri'
    require 'json'

    attr_reader :release, :gene_ids, :gene_seqs

    def initialize
        puts "Getting gene release ..."
        @release = get_gene_release

        puts "Getting gene ids ..."
        @gene_ids = get_gene_ids

        puts "Getting gene sequences ..."
        @gene_seqs = get_gene_sequences

        puts "Verifying data ..."
        verify_genes
    end

    private

    def get_gene_release
        path = '/info/data/?'
        response_type = 'application/json'

        result = request_from_ensembl_rest_server(path, response_type)
        if result
            json = JSON.parse(result)
            json["releases"].join("/")
        else
            return ""
        end
    end

    def get_gene_ids
        # NOTE: no idea how to retrieve this information using the REST-API...

        path = "http://www.ensembl.org/biomart/martservice?"
        # request = "get_all_ensembl_geneids.xml"
        request = '\'query=<!DOCTYPE Query><Query  virtualSchemaName = "default" formatter = "CSV" header = "0" uniqueRows = "1" count = "" datasetConfigVersion = "0.6" ><Dataset name = "hsapiens_gene_ensembl" interface = "default" ><Attribute name = "ensembl_gene_id" /></Dataset></Query>\''
        response = %x[curl -s -d #{request} #{path}]

        # filter: accepting only lines starting with an Ensembl gene Id (and hopefully containing nothing else...)
        response.split("\n").select{|str| str.start_with?("ENSG")}
    end

    def get_gene_sequences
        response_type = 'text/plain'

        @gene_ids.collect do |id|
            # NOTE: mask_feature returns sequence with exons in upper in introns in lower case.
            path = "/sequence/id/#{id}?mask_feature=1;"
            request_from_ensembl_rest_server(path, response_type)
        end
    end

    def verify_genes
        # delete gene_ids if corresponding gene_seq is false
        @gene_ids.keep_if.each_with_index{|str, ind| @gene_seqs[ind] }
        # delete gene_seqs if gene_seq is false
        @gene_seqs.keep_if{|str| str }
    end

    # returns false if an error occured
    def request_from_ensembl_rest_server(path, response_type)
        server = 'http://rest.ensembl.org'
        url = URI.parse(server)
        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Get.new(
            path, {'Content-Type' => response_type}
        )
        response = http.request(request)

        if response.code != "200"
            puts "Invalid response: #{response.code}"
            puts response.body

            return false
        end

        response.body
    end
end