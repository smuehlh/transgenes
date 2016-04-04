class ToGene
    class GenebankToGene

        attr_reader :gene_name, :exons, :introns

        def self.valid_file_extensions
            [".gb"]
        end

        def initialize(file)
            @file = file
        end

        def split_file_into_single_genes
            # INFO: only first gene description line will be safed.
            @gene_records_by_gene_starts = {}
            @gene_sequence = ""

            @current_gene_start = nil
            @current_feature = nil
            line_number = 0
            IO.foreach(@file) do |line|
                line_number += 1
                line = line.chomp

                update_current_feature(line)
                update_current_gene_start(line_number) if is_new_gene(line)
                save_gene_record(line) if is_gene_record
                save_gene_sequence(line) if is_gene_sequence
            end
            @gene_records_by_gene_starts
        end

        def is_partial_gene(gene_record)
            gene_record.each do |line|
                return true if is_line_containing_partial_gene_record(line)
            end
            false
        end

        def parse_gene_record(gene_record)
            @gene_name = ""
            @exons = []
            @introns = []

            @exon_positions = ""
            @is_gene_on_minus_strand = false
            is_line_containing_exon_positions = true
            gene_record.each do |line|
                if is_line_containing_gene_name(line)
                    save_gene_name(line)
                else
                    save_exon_positions(line)
                end
            end

            cut_gene_sequence_into_exons_and_introns
            fix_minus_strand if @is_gene_on_minus_strand
        end

        private

        def is_line_containing_partial_gene_record(line)
            ! is_line_containing_gene_name(line) &&
                (line[/(<\d|\d<)/] || line[/(\d>|>\d)/])
        end

        def is_new_gene(line)
            subfeature_key = get_subfeature_key(line)
            @current_feature == "FEATURES-CDS-exonpos" &&
                is_new_cds_subfeature_line(subfeature_key)
        end

        def is_gene_record
            @current_feature == "FEATURES-CDS-exonpos" ||
                @current_feature == "FEATURES-CDS-genename"
        end

        def is_gene_sequence
            @current_feature == "ORIGIN"
        end

        def update_current_gene_start(line_number)
            @current_gene_start = line_number
        end

        def save_gene_record(line)
            @gene_records_by_gene_starts[@current_gene_start] = [] if
                ! @gene_records_by_gene_starts.key?(@current_gene_start)

            @gene_records_by_gene_starts[@current_gene_start].push(line.chomp)
        end

        def save_gene_sequence(line)
            line = line.strip
            line_wo_invalid_chars = Nucleotide.remove_invalid_chars(line)
            @gene_sequence += line_wo_invalid_chars unless line == "ORIGIN"
        end

        def update_current_feature(line)
            feature_key = get_feature_key(line)
            @current_feature =
                if is_new_or_continued_origin_line(feature_key)
                    "ORIGIN"
                elsif is_new_or_continued_feature_line(feature_key)
                    subfeature_key = get_subfeature_key(line)
                    if is_new_or_continued_cds_subfeature_line(subfeature_key)
                        subsubfeature_key = get_subsubfeature_key(line)
                        if is_new_or_continued_exonpos_subsubfeature_line(subsubfeature_key)
                            "FEATURES-CDS-exonpos"
                        elsif is_new_genename_subsubfeature_line(subsubfeature_key)
                            "FEATURES-CDS-genename"
                        else
                            "FEATURES-CDS"
                        end
                    else
                        "FEATURES"
                    end
                else
                    nil
                end
        end

        # helper-methods "update_current_feature"
        def split_line_into_feature_key_and_values(line)
            # HACK
            # 1) split after each space-character
            # 2) concatenate all successive space-characters into single one
            parts = line.split(/[[:space:]]/)
            parts.each_with_index do |item, ind|
                parts[ind] = nil if parts[ind] == parts[ind+1]
            end.compact
        end

        def get_feature_key(line)
            split_line_into_feature_key_and_values(line)[0]
        end

        def get_subfeature_key(line)
            parts = split_line_into_feature_key_and_values(line)
            if parts.size >= 4 && parts[0].empty? && parts[2].empty?
                parts[1]
            else
                ""
            end
        end

        def get_subsubfeature_key(line)
            if line[/^\s+CDS.+\d/]
                "exonpos"
            elsif match = line[/\/\w+=/]
                match
            else
                ""
            end
        end

        def is_new_or_continued_origin_line(key)
            key == "ORIGIN" || (@current_feature == "ORIGIN" && key.empty?)
        end

        def is_new_or_continued_feature_line(key)
            key == "FEATURES" || (@current_feature =~ /^FEATURES/ && key.empty?)
        end

        def is_new_or_continued_cds_subfeature_line(key)
            is_new_cds_subfeature_line(key) || (@current_feature =~ /^FEATURES-CDS/ && key.empty?)
        end

        def is_new_cds_subfeature_line(key)
            key == "CDS"
        end

        def is_new_or_continued_exonpos_subsubfeature_line(key)
            key == "exonpos" || (@current_feature == "FEATURES-CDS-exonpos" && key.empty?)
        end

        def is_new_genename_subsubfeature_line(key)
            key == "/gene="
        end

        # helper-methods "parse_gene_record"
        def is_line_containing_gene_name(line)
            line[/\/gene=/]
        end

        def save_gene_name(line)
            @gene_name += line.regexp_delete(/(\s+\/gene=\"|\")/).strip
        end

        def save_exon_positions(line)
            @is_gene_on_minus_strand = true if line[/complement/]
            @exon_positions += line.regexp_delete(/[^\d\.,]/)
        end

        def cut_gene_sequence_into_exons_and_introns
            positions = convert_exon_description_to_gene_indices

            last_exon_stop = nil
            positions.each do |exon_start, exon_stop|
                # preceeding intron - all but the very first exon have one
                # save in downcase
                if last_exon_stop
                    intron_start = last_exon_stop + 1
                    intron_stop = exon_start - 1
                    @introns.push(
                        @gene_sequence[intron_start..intron_stop].downcase
                    )
                end
                # exon - save in uppercase
                @exons.push(
                    @gene_sequence[exon_start..exon_stop].upcase
                )
                last_exon_stop = exon_stop
            end
        end

        def fix_minus_strand
            @exons = @exons.reverse
            @introns = @introns.reverse

            @exons = @exons.map{ |e| Nucleotide.reverse_complement(e).upcase }
            @introns = @introns.map{ |i| Nucleotide.reverse_complement(i).downcase }
        end

        def convert_exon_description_to_gene_indices
            @exon_positions.split(",").map do |range|
                range.split("..").map{|pos| Counting.human_to_ruby(pos.to_i)}
            end
        end
    end
end