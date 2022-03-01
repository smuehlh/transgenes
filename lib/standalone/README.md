# Sequence Optimizer

A script to make a gene work better as a transgene by introducing synonymous mutations to match site-specific codon usage in human one- or two-exon genes.

__Author__ Stefanie Mühlhausen
__Affiliation__ Laurence D Hurst
__Contact__ Laurence Hurst (l.d.hurst@bath.ac.uk)

This program comes with ABSOLUTELY NO WARRANTY

We generate multiple, independent variants. For every variant we inspect all synonymous sites, one at a time. For each synonymous codon we test for the potential to increase GC3, human codon usage or position-dependent codon occurrences in human one- or two-exons genes (Ensemble data) [set via `--strategy` option] and score accordingly. Underlying functions for position-dependent favourability stem from a matrix of probabilities for the last nucleotide in a codon box (six-fold codon boxes being split into their respective four-fold and two-fold sub-boxes), fitted into curves as a function of position.

Optionally, we also score a codon by ESE resemblance, favouring or disfavouring codons in vicinity to exon-intron borders resembling known ESE motifs [set via `--ese-strategy` option].

Per synonymous site, the scores for synonymous codons are normalised such that they sum up to 1. To select one of the thusly scored synonymous codons we draw a random number _r_ in interval [0, 1] and select the codon for which sum of all codon scores seen so far exceeds _r_. Thus, the higher the score the likelier a codon is selected. The codon list is shuffled before codon selection to ensure selection between synonymous codons with same score remains non-deterministic. We set all stop codons to TAA as this is reported to be strongest in human.

We first generate 1000 variants. Subsequently, we log the full variant cloud and select one for output based on target GC3 and ESE resemblance [set via `--select-by` option].

## Requirements

 - Ruby 2.4
 - Optionally: gem byebug

The byebug gem is needed for debugging only. If you don't need it, or don't have it installed, comment out lines containing  `require 'byebug'` in files `sequence_optimizer.rb`, `testsuite.rb` and `tweak_sarscov2_genome.rb`.


## Usage

```bash
ruby sequence_optimizer.rb
```

## ESE datasets

ESE datasets have been obtained from the following websites and publications:

- INT3
  > Eva Fernández Cáceres and Laurence D Hurst: The evolution, impact and
  > properties of exonic splice enhancers. Genome Biology. 2013, 14:R143.
  > DOI: 10.1186/gb-2013-14-12-r143

- RESCUE-ESE
  > Fairbrother WG, Yeh RF, Sharp PA, Burge CB: Predictive identification
  > of exonic splicing enhancers in human genes. Science. 2002, 297:
  > 1007-1013. DOI: 10.1126/science.1073774.
  > http://genes.mit.edu/burgelab/rescue-ese/ESE.txt

- PESE (hexamers with min 7 occurrences in the original list of octamers)
  > Zhang XHF, Chasin LA: Computational definition of sequence motifs
  > governing constitutive exon splicing. Genes Dev. 2004, 18: 1241-1250.
  > DOI: 10.1101/gad.1195304.

- ESR
  > Goren A, Ram O, Amit M, Keren H, Lev-Maor G, Vig I, Pupko T, Ast G:
  > Comparative analysis identifies exonic splicing regulatory sequences -
  > The complex definition of enhancers and silencers. Mol Cell. 2006, 22:
  > 769-781. DOI: 10.1016/j.molcel.2006.05.008.

- Ke-ESE400 (top 400 ESE)
  > Ke S, Shang S, Kalachikov SM, Morozova I, Yu L, Russo JJ, Ju J, Chasin
  > LA: Quantitative evaluation of all hexamers as exonic splicing
  > elements. Genome Res. 2011, 21: 1360-1374. DOI: 10.1101/gr.119628.110.


#  Tweaking Sars-CoV-2

[branch corvid19]

_or:_ Who doesn't like corvids over SARS-CoV-2?

In a surprising 2020 spin-off, we've adjusted our standalone tool to work in opposite direction: attenuate, rather than enhance, translation efficiency in humans.

We attenuate each SARS-CoV-2 gene individually in the direction opposite to its selection pressure for optimum fitness. Specifically, we increase a genes’ CpG content as a function of its CpG enrichment and its UpA content as a function of its UpA enrichment. In addition, we seek to increase U content. The more CpG (UpA) depleted a gene is, the higher its likelihood to have its CpG (UpA) content increased; the less CpG (UpA) depleted a gene is, the lesser the likelihood for CpG and UpA increase.

When using this branch of our software, please cite:

> Alan M Rice, Atahualpa Castillo Morales, Alexander T Ho, Christine
> Mordstein, Stefanie Mühlhausen, Samir Watson, Laura Cano, Bethan
> Young, Grzegorz Kudla, Laurence D Hurst.
>  Evidence for Strong Mutation Bias toward, and Selection against, U Content in SARS-CoV-2: Implications for Vaccine Design
>   _Molecular Biology and Evolution_, msaa188,
> [https://doi.org/10.1093/molbev/msaa188](https://doi.org/10.1093/molbev/msaa188)


## Usage

```bash
ruby tweak_sarscov2_genome.rb -i <sars-cov-2-genomefile.fasta> -o <attenuated-sars-cov-2-genomefile.fasta>
```

## Tests

A QuickTest style test suit generating a short, random sequence and attenuating it according to randomly specified CpG and UpA enrichment values. Generated sequence variants are then tested for CpG, UpA and U content, stop codon and mutations being synonymous only.

```bash
ruby testsuite.rb
```

# License

[GNU GPL](./COPYING)
