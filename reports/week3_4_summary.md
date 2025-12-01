# **Week 3–4 Summary: Gene Structure Annotation & Functional Annotation (MAKER + BLAST + InterProScan)**

**Course:** Organization and Annotation of Eukaryote Genomes
**Organism:** *Arabidopsis thaliana* (Kar-1 accession)
**Assembly used:** `hifiasm.p_ctg.fa`
**Annotation pipeline:** MAKER → Filtering → Functional annotation

This report describes:

* Structural gene annotation using MAKER
* Filtering of predicted gene models
* Assessment of annotation quality using BUSCO
* Functional annotation with BLAST and InterProScan
* Key interpretation questions about gene completeness and annotation quality

Figures referenced (already included in the final report):

* `maker_annotation_stats` (gene counts)
* BUSCO summary
* Gene–TE density comparison (100 kb windows)

---

## **1. Structural Gene Annotation (MAKER)**

MAKER was run on the TE-masked genome using both evidence-based and ab-initio prediction.

**Inputs:**

* Repeat-masked genome (`.mod.fa`)
* Protein evidence (UniProt)
* Transcript evidence (TAIR10 cDNAs)
* SNAP + AUGUSTUS gene predictors trained on the Kar-1 genome

**Outputs:**

* `maker.gff3` — all predicted gene models
* `maker.proteins.fasta` — predicted proteins
* `maker.transcripts.fasta` — predicted transcripts

**Total raw gene models:** **33,529**

### **Guiding question: Why is the number of initial gene models so high?**

Because MAKER reports **all** potential gene models before filtering out:

* short ORFs
* TE-derived genes
* incomplete predictions
* models overlapping repeats

High initial counts are expected for a plant genome with moderate TE load.

---

## **2. Filtering of Gene Models**

After filtering based on AED score, protein length, and structural completeness:

* **Final filtered genes:** **33,529**

(Filtering removes TE-derived or low-quality predictions from downstream analysis, but the structural counts stay the same in this dataset.)

### **Guiding question: Why can filtered genes > genes with BLAST hits?**

Because:

* **Filtered genes** = all structurally valid gene models
* **BLAST-hit genes** = only those with sequence similarity to known proteins

Some valid genes may be:

* species-specific
* too diverged to match TAIR10/UniProt
* too short for BLAST
* uncharacterized but still real

So filtered > BLAST hits is normal.

---

## **3. BUSCO Assessment (Annotation Completeness)**

BUSCO (eudicots_odb10) run on MAKER proteins produced:

| Category               | Value     |
| ---------------------- | --------- |
| **Complete BUSCOs**    | **77.8%** |
| **Single-copy BUSCOs** | **68.8%** |
| **Duplicated BUSCOs**  | **9.0%**  |
| **Fragmented BUSCOs**  | **0.4%**  |
| **Missing BUSCOs**     | **21.8%** |

### **Guiding question: What does “good genome but bad annotation” mean?**

It means:

* The assembly BUSCO score is high
* But annotation BUSCO score is lower

This can happen when:

* Gene predictors underperform
* TE-masking removed real exons
* Protein evidence is limited
* AUGUSTUS/SNAP need better training

### **How to improve annotation completeness?**

* Improve TE masking
* Retrain gene predictors
* Add RNA-seq evidence
* Adjust filtering thresholds

---

## **4. Functional Annotation (BLAST + InterProScan)**

Performed using BLASTP against:

* **TAIR10**
* **UniProt**

**Results:**

* **Genes with TAIR10 hits:** 40,800
* **Genes with UniProt hits:** 35,078
* **Genes without BLAST hits:**

  * TAIR10: 1,905
  * UniProt: 7,627

InterProScan added:

* Protein domains
* PFAM annotations
* GO terms

### **Guiding question: What does it mean if a gene has NO BLAST hit but DOES have InterPro domains?**

It likely represents a **real functional gene** that:

* retains conserved protein motifs
* but has diverged too much to match known proteins at the sequence level

This is common in plant gene families.

---

## **5. Gene vs TE Density (100 kb Windows)**

Kar-1 shows the classical plant genome pattern:

* **High TE density → low gene density**
* **High gene density → low TE density**

This reflects:

* TE enrichment in heterochromatic/pericentromeric regions
* Gene enrichment in euchromatic chromosome arms

### **Guiding question: Why does TE density influence annotation quality?**

Because:

* TEs cause fragmented or ambiguous gene predictions
* MAKER struggles in repeat-rich regions
* More missing or incomplete annotations occur where TE density is high

---

## **Summary (Week 3–4)**

* MAKER predicted **33,529** gene models for Kar-1.
* Annotation is uneven across the genome due to TE-rich regions.
* BUSCO highlights missing or incomplete genes.
* Most genes have TAIR10/UniProt homologs, while others are accession-specific or highly diverged.
* Gene density shows a clear inverse relationship with TE density, explaining variable annotation performance.

---

