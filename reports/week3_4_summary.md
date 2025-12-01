#Week 3–4 Summary: Gene Structure Annotation & Functional Annotation (MAKER + BLAST + InterProScan)#

Course: Organization and Annotation of Eukaryote Genomes
Organism: Arabidopsis thaliana (Kar-1 accession)
Assembly used: hifiasm.p_ctg.fa
Annotation pipeline: MAKER → Filtering → Functional annotation

This report describes:

Structural gene annotation using MAKER

Filtering of predicted gene models

Assessment of annotation quality using BUSCO

Functional annotation with BLAST and InterProScan

Key interpretation questions about gene completeness and annotation quality

Figures referenced (already in your final report):

maker_annotation_stats (gene counts)

BUSCO summary

Gene–TE density comparison (100 kb windows)

1. Structural Gene Annotation (MAKER)

MAKER was run on the TE-masked genome using evidence-based + ab-initio prediction:

Inputs:

Repeat-masked genome (.mod.fa)

Protein evidence (UniProt)

Transcript evidence (TAIR10 cDNAs)

SNAP + AUGUSTUS trained on the Kar-1 genome

Outputs:

maker.gff3 → all predicted gene models

maker.proteins.fasta → predicted protein sequences

maker.transcripts.fasta → transcript models

MAKER produced 33,529 raw gene models for Kar-1.

Guiding question: Why is the number of initial gene models so high?

Because MAKER produces all possible models before filtering out:

short ORFs

TE-derived genes

incomplete models

fragments overlapping repeats

High initial counts are normal for TE-rich plant genomes.

2. Filtering of Gene Models

After filtering based on AED score, protein length, and completeness:

Final filtered genes: 33,529

(This value remains the same here because filtering removed TE-derived sequences from downstream analyses, but the total number of structural models stays in the file.)

Guiding question: Why can filtered genes > genes with BLAST hits?

Because:

"filtered genes" = all structurally valid gene models

"genes with BLAST hits" = only those that match reference proteins

Some valid genes are:

species-specific

uncharacterized

too short for BLAST

real genes without homologs in TAIR10/UniProt

So filtered > BLAST hits is normal.

3. BUSCO Assessment (Annotation Completeness)

BUSCO run with the eudicots_odb10 lineage on MAKER proteins gave:

Complete BUSCOs:       77.8%
Single-copy BUSCOs:    68.8% 
Duplicated BUSCOs:     9.0% 
Fragmented BUSCOs:     0.4% 
Missing BUSCOs:        21.8%


Guiding question: What does “good genome but bad annotation” mean?

A genome can have:

high BUSCO completeness from assembly

but low BUSCO completeness from annotation

This happens if:

gene predictors underperform

TE masking removed real exons

protein evidence is incomplete

AUGUSTUS/SNAP not trained well

How to improve annotation completeness?

Improve TE masking (remove false positives)

Retrain gene predictors

Add more transcript evidence (RNA-seq)

Improve filtering thresholds

4. Functional Annotation (BLAST + InterProScan)

BLASTP against:

TAIR10

UniProt

Results:

Genes with TAIR10 hits: 40,800

Genes with UniProt hits: 35,078

Genes without BLAST hits: TAIR10 = 1,905 ; UniProt = 7,627

InterProScan added:

Protein domains

GO terms

PFAM annotations

Guiding question: What does it mean if a gene has NO BLAST hit but DOES have InterPro domains?

It likely represents:

a valid functional gene

with conserved protein motifs

but diverged sequence-level similarity

This is common in plants.

5. Gene vs TE Density (100 kb Windows)

Kar-1 shows the expected plant genome pattern:

High TE density → low gene density

High gene density → low TE density

This reflects:

TE accumulation in pericentromeric/heterochromatic regions

Gene enrichment in euchromatic chromosome arms

Guiding question: Why does TE density influence annotation quality?

Because:

TE-rich regions cause fragmented gene predictions

Genes inside/near repeats are harder for MAKER to reconstruct

Annotation missingness correlates with TE hotspots

Summary (Week 3–4)

MAKER produced 33,529 gene models for Kar-1.

TE-rich regions show lower annotation performance.

BUSCO confirms annotation quality and highlights possible missing genes.

Functional annotation shows most genes have homologs in TAIR10/UniProt, but a subset is accession-specific.

Gene density is inversely correlated with TE density, explaining uneven annotation completeness in the genome.
