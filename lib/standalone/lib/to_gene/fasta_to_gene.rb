class ToGene
    class FastaToGene

        attr_reader :gene_name, :exons, :introns

        def self.valid_file_extensions
            [".fas", ".fa", ".fasta"]
        end

        def initialize(file)
            @file = file
            $logger.info("Treating input as FASTA.\nExpecting to find FASTA headers.")
        end

        def split_file_into_single_genes
            @gene_records_by_gene_starts = {}
            @current_gene_start = nil

            line_number = 0
            IO.foreach(@file) do |line|
                line_number += 1
                line = line.chomp
                next if is_comment(line)

                update_current_gene_start(line_number) if is_line_starting_new_gene_record(line)
                save_gene_record(line)
            end
            @gene_records_by_gene_starts
        end

        def is_partial_gene(gene_record)
            gene_record.each do |line|
                return true if is_line_starting_partial_gene_record(line)
            end
            false
        end

        def parse_gene_record(gene_record)
            @gene_name = ""
            @exons = []
            @introns = []

            @last_sequence_sniplet = nil
            gene_record.each do |line|
                # lines contain either gene name or exons/introns
                if is_line_starting_new_gene_record(line)
                    save_gene_name(line)
                else
                    save_exons_and_introns(line)
                end
            end
        end

        private

        def is_comment(line)
            line.start_with?(";")
        end

        def is_line_starting_new_gene_record(line)
            line.start_with?(">")
        end

        def is_line_starting_partial_gene_record(line)
            is_line_starting_new_gene_record(line) && line["partial"]
        end

        def update_current_gene_start(line_number)
            @current_gene_start = line_number
            $logger.info("Identified line #{@current_gene_start} as FASTA header.\nWill treat following lines as FASTA sequence.") 
        end

        def save_gene_record(line)
            @gene_records_by_gene_starts[@current_gene_start] = [] if
                ! @gene_records_by_gene_starts.key?(@current_gene_start)

            @gene_records_by_gene_starts[@current_gene_start].push(line)
        end

        # helper methods parse_wanted_gene_record
        def save_gene_name(line)
            @gene_name = line.sub(">", "")
        end

        def save_exons_and_introns(line)
            exon_intron_sniplets = split_line_into_exons_and_introns(line)
            add_sniplets_to_exons_and_introns(exon_intron_sniplets)
        end

        def split_line_into_exons_and_introns(str)
            exon_intron_sniplets = []
            last_char = nil
            str.each_char do |char|
                exon_intron_sniplets.push(
                    if char.is_upper?
                        new_or_updated_uppercase_item(char, last_char, exon_intron_sniplets)
                    else
                        new_or_updated_lowercase_item(char, last_char, exon_intron_sniplets)
                    end
                )
                last_char = char
            end
            exon_intron_sniplets
        end

        def add_sniplets_to_exons_and_introns(exon_intron_sniplets)
            exon_intron_sniplets.each do |sniplet|
                if sniplet.is_upper?
                    @exons.push(
                        new_or_updated_uppercase_item(
                            sniplet, @last_sequence_sniplet, @exons
                        )
                    )
                else
                    @introns.push(
                        new_or_updated_lowercase_item(
                            sniplet, @last_sequence_sniplet, @introns
                        )
                    )
                end
                @last_sequence_sniplet = sniplet
            end
        end

        def new_or_updated_uppercase_item(str, last_str, items)
            if last_str && last_str.is_upper?
                items.pop + str
            else
                str
            end
        end

        def new_or_updated_lowercase_item(str, last_str, items)
            if last_str && last_str.is_lower?
                items.pop + str
            else
                str
            end
        end
    end
end