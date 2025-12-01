# **Week 5–6 Summary: Orthology, Synteny & Pangenome Analysis (OrthoFinder + GENESPACE)**

**Course:** Organization and Annotation of Eukaryote Genomes
**Organism:** *Arabidopsis thaliana* (Kar-1 accession)
**Tools used:** OrthoFinder → GENESPACE → Pangenome matrix
**Genomes compared:** TAIR10 (reference) + Altai_5, Are_6, Est_0, Etna_2, Ice_1, Kar_1, Taz_0

This report describes:

* Orthogroup inference using OrthoFinder
* Synteny-aware refinement with GENESPACE
* Identification of core, accessory, and accession-specific orthogroups
* Pangenome matrix interpretation
* Genome structure conservation via synteny maps

**Figures referenced (already in your final report):**

* `Kar_1_vs_TAIR10.syntenicHits.pdf`
* `Kar_1_geneOrder.rip.pdf`
* Table of core vs accession-specific genes (Table 3)

---

## **1. Orthogroup Inference with OrthoFinder**

OrthoFinder was run using protein FASTA files from all accessions plus TAIR10.

**Outputs included:**

* `Orthogroups.txt` — mapping of every gene to an orthogroup
* `Orthologues/` — pairwise ortholog tables
* `Orthogroups.GeneCount.tsv` — size of each orthogroup in each accession

These assignments are based on **sequence similarity alone**, not genomic position.

### **Guiding Question: What does OrthoFinder give?**

OrthoFinder provides:

* Orthogroups (gene families) across all genomes
* Classification of orthologs / paralogs
* Estimates of gene family expansions
* A first overview of shared vs unique genes

This is the base layer before adding synteny information from GENESPACE.

---

## **2. GENESPACE: Synteny-Constrained Orthology**

GENESPACE integrates:

* BLAST/DIAMOND hits
* OrthoFinder orthogroups
* Gene order (synteny) along chromosomes

**Inputs:**

* BED files (gene coordinates) for each accession
* Peptide FASTAs
* OrthoFinder results

**Outputs:**

* `pangenes.rds` — synteny-aware pangenome matrix
* Riparian synteny plots
* Syntenic hit maps (pairwise with TAIR10)

GENESPACE refines orthogroups by requiring that the matching genes occur in **conserved genomic positions**, reducing false paralogs.

### **Guiding Question: Why add synteny?**

Because sequence similarity alone cannot distinguish:

* Old paralogs
* Tandem duplicates
* Misassigned TE-derived ORFs
* Real positionally conserved orthologs

GENESPACE solves this by using gene order.

---

## **3. Pangenome Results (pangenome_matrix.rds)**

GENESPACE produced a pangenome matrix summarizing gene presence/absence across the 9 genomes.

**For Kar-1:**

* **Orthogroups in Kar-1:** included in matrix
* **Core orthogroups:** **18,149** (present in all accessions)
* **Accession-specific orthogroups:** **704**
* **Genes in core orthogroups:** **18,931**
* **Genes in accession-specific orthogroups:** **716**

These numbers are from your final GENESPACE run.

### **Guiding Question: What do these values represent?**

* **Core orthogroups** = evolutionarily conserved gene families found across all accessions.
* **Accession-specific orthogroups** = genes unique to Kar-1 (real biological variation *or* annotation differences).
* **Core genes** = genes inside core orthogroups.
* **Accession-specific genes** = Kar-1 genes lacking orthologs in all other accessions.

---

## **4. Synteny With the Reference (TAIR10)**

### **Figure: `Kar_1_vs_TAIR10.syntenicHits.pdf`**

This plot shows syntenic anchor hits between Kar-1 and TAIR10 across all chromosomes.

* Strong diagonal patterns indicate **high conservation of gene order**.
* Scattered noise indicates **small rearrangements or annotation differences**.

### **Guiding Question: What does strong synteny mean?**

It indicates:

* High-quality assembly
* Minimal large-scale rearrangements
* Good structural annotation
* Close evolutionary distance (expected in Arabidopsis accessions)

---

## **5. Multi-Genome Synteny (Riparian Plot)**

### **Figure: `Kar_1_geneOrder.rip.pdf`**

The riparian plot shows:

* One vertical column per genome
* Chromosomes represented as curved polygons
* Colored “braids” linking syntenic blocks between genomes

Kar-1 aligns cleanly with TAIR10 and other accessions, forming continuous syntenic ribbons.

### **Guiding Question: What does a break in a ribbon mean?**

It usually represents:

* Structural rearrangements
* Assembly fragmentation
* Misannotation (e.g., misplaced gene models)
* Accessions differing in gene order (biological variation)

Kar-1 shows typical Arabidopsis-level conservation, with no major disruptions.

---

## **6. Interpreting Accessory & Unique Gene Families**

Kar-1 contains **716 accession-specific genes**.

### **Guiding Question: Are these real or annotation artifacts?**

They can represent:

**Real biology:**

* Local gene duplications
* Presence/absence variants (PAVs)
* Genes in TE-rich regions
* Adaptation-related genes

**Technical causes:**

* Differences in MAKER filtering
* Missing annotation in other accessions
* TE-derived ORFs incorrectly annotated as genes
* Partial gene models not matching orthogroups

Your earlier figures (TE–gene density) support that some of these genes lie in TE-rich regions, where annotation is harder.

---

## **7. Summary (Week 5–6)**

* OrthoFinder generated similarity-based orthogroups across 9 Arabidopsis genomes.
* GENESPACE added synteny information to refine orthology and build a high-quality pangenome matrix.
* Kar-1 contains **18,931 core genes** and **716 accession-specific genes**.
* Synteny with TAIR10 is strong, confirming assembly quality and close evolutionary distance.
* Accessory and accession-specific orthogroups likely arise from a combination of real variation and TE-related annotation noise.
* These results complete the comparative genomics component of the project.

---
