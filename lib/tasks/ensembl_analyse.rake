namespace :ensembl do
    namespace :analyse do

        desc "Count third sites by position for 1- and 2-exon genes"
        task third_sites: :environment do
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'genetic_code.rb')
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'synonymous_sites.rb')

            # init third-site counts
            counts = {} # outer/inner hash: codon/ position in gene
            GeneticCode.valid_codons.each do |codon|
                counts[codon] = {}
            end

            EnsemblGene.find_each do |gene|
                parsed_gene = parse_gene(gene)
                next unless parsed_gene # parsing was unsuccessfull
                next unless parsed_gene[:exons].size <= 2

                cds = parsed_gene[:exons].join("")
                codons = GeneticCode.split_cdna_into_codons(cds)
                next unless codons.first == "ATG"
                next unless GeneticCode.is_stopcodon(codons.last)

                codons.each_with_index do |codon, aa_pos|
                    # 1-exon gene: collect all positions
                    # 2-exon gene: collect only pos that are _not_ in vincinity to the intron
                    next if GeneticCode.is_stopcodon(codon)
                    next if is_near_intron_border(aa_pos, parsed_gene)

                    related_codons = GeneticCode.get_codons_same_third_site_site_and_degeneracy_group(codon)
                    counts = update_counts(counts, related_codons, aa_pos)
                end
            end

            # save counts
            fh = File.open(
                File.join(
                    Rails.root, 'lib', 'standalone', 'lib', 'scores', 'codon_usage_data', "third_site_counts-ensembl-v#{EnsemblGene.first.version}.rb"
                ), "w"
            )
            fh.print "Third_site_counts = "
            fh.print counts
            fh.close
        end

        desc "Count third sites by distance to intron in 2-exon genes"
        task third_sites_near_intron: :environment do
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'genetic_code.rb')
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'synonymous_sites.rb')

            # init third-site counts
            counts = {} # outer/inner hash: codon/ distance to intron
            GeneticCode.valid_codons.each do |codon|
                counts[codon] = {}
            end

            EnsemblGene.find_each do |gene|
                parsed_gene = parse_gene(gene)
                next unless parsed_gene # parsing was unsuccessfull
                next unless parsed_gene[:exons].size == 2

                cds = parsed_gene[:exons].join("")
                codons = GeneticCode.split_cdna_into_codons(cds)
                next unless codons.first == "ATG"
                next unless GeneticCode.is_stopcodon(codons.last)

                codons.each_with_index do |codon, aa_pos|
                    # 2-exon gene: collect only pos that are in vincinity to the intron
                    next if GeneticCode.is_stopcodon(codon)
                    next unless is_near_intron_border(aa_pos, parsed_gene)

                    related_codons = GeneticCode.get_codons_same_third_site_site_and_degeneracy_group(codon)
                    distance = distance_to_intron(aa_pos, parsed_gene)
                    counts = update_counts(counts, related_codons, distance)
                end
            end

            # save counts
            fh = File.open(
                File.join(
                    Rails.root, 'lib', 'standalone', 'lib', 'scores', 'codon_usage_data', "third_site_counts_around_intron-ensembl-v#{EnsemblGene.first.version}.rb"
                ), "w"
            )
            fh.print "Third_site_counts_near_intron = "
            fh.print counts
            fh.close
        end

        desc "Calculate average GC content of 1- and 2-exon genes"
        task gc: :environment do
            gc_one_exon_genes = []
            gc_two_exon_genes = []

            EnsemblGene.find_each do |gene|
                parsed_gene = parse_gene(gene)
                next unless parsed_gene # parsing was unsuccessfull
                n_exons = parsed_gene[:exons].size
                gc = calc_gc(parsed_gene[:exons].join(""))
                if n_exons == 1
                    gc_one_exon_genes.push gc
                elsif n_exons == 2
                    gc_two_exon_genes.push gc
                end
            end

            average_one_exon_genes = Statistics.mean(gc_one_exon_genes)
            average_two_exon_genes = Statistics.mean(gc_two_exon_genes)
            puts "Average GC (1 exon genes): #{average_one_exon_genes}"
            puts "Average GC (1 exon genes): #{average_two_exon_genes}"
        end

        def parse_gene(gene)
            gene_parser = WebinputToGene.new(
                # mimic webinput
                {name: "CDS", data: gene.to_fasta}, false
            )
            # NOTE: there should be only one gene record. therefore, taking the first should be save. a record consists of starting line and data. take data only
            gene_parser.get_records.values.first
        end

        def is_near_intron_border(aa_pos, gene)
            if gene[:exons].size == 1
                return false
            else
               syn_sites = SynonymousSites.new(gene[:exons], gene[:introns])
               cds_pos_third_site = convert_to_pos_in_cds(aa_pos)
               return syn_sites.is_in_proximity_to_intron(cds_pos_third_site)
            end
        end

        def distance_to_intron(aa_pos, gene)
           syn_sites = SynonymousSites.new(gene[:exons], gene[:introns])
           cds_pos_third_site = convert_to_pos_in_cds(aa_pos)
           nt_pos = syn_sites.get_nt_distance_to_intron(cds_pos_third_site)
           nt_pos/3
        end

        def update_counts(counts, related_codons, pos)
            related_codons.each do |codon|
                counts[codon][pos] = 0 unless counts[codon][pos]
                counts[codon][pos] += 1
            end
            counts
        end

        def calc_gc(cds)
            (cds.count("G") + cds.count("C"))/cds.size.to_f
        end

        def convert_to_pos_in_cds(aa_pos)
            aa_pos * 3 + 2
        end
    end
end