namespace :ensembl do
    namespace :analyse do

        desc "Create matrix based on one-exon genes"
        task third_sites: :environment do
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'genetic_code.rb')

            # init third-site counts
            counts = {} # outer/inner hash: codon/ position in gene
            GeneticCode.valid_codons.each do |codon|
                counts[codon] = {}
            end

            EnsemblGene.find_each do |gene|
                parsed_gene = parse_gene(gene)
                next unless parsed_gene # parsing was unsuccessfull
                next unless parsed_gene[:exons].size == 1

                cds = parsed_gene[:exons].join("")
                codons = GeneticCode.split_cdna_into_codons(cds)
                next unless codons.first == "ATG"

                codons.each_with_index do |codon, pos_in_gene|
                    next if GeneticCode.is_stopcodon(codon)

                    related_codons = GeneticCode.get_codons_same_third_site_and_degeneracy(codon)
                    counts = update_counts(counts, related_codons, pos_in_gene)
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
    end
end