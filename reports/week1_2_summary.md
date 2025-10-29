# Week 1–2 Summary – Transposable Element (TE) Annotation, Classification, and Dynamics

Course: Organization and Annotation of Eukaryote Genomes  
Organism: Arabidopsis thaliana (accession-level assembly)  
Assembly used for annotation: `hifiasm.p_ctg.fa` (primary contigs from hifiasm)

This report describes:
1. Annotation of transposable elements (TEs) with EDTA  
2. TE composition and genome coverage  
3. Genomic distribution of TEs  
4. Age structure of intact LTR retrotransposons (LTR-RTs)  
5. Clade-level classification of LTR-RTs using TEsorter  
6. Inference on TE dynamics (recent vs ancient bursts of activity)

Figures referenced:
- `01_LTR_Copia_Gypsy_cladelevel.png`
- `02_TE_density_circlize.png`
- `03_clade_counts.png`
---

## 1. Intact full-length LTR retrotransposons (LTR-RTs)

EDTA output was used to identify intact, full-length LTR retrotransposons (LTR-RTs), using the file  
`hifiasm.p_ctg.fa.mod.LTR.intact.raw.gff3`.

For each intact LTR-RT:
- The identity between the two LTRs was calculated (LTR-LTR percent identity).
- Superfamily (Copia or Gypsy) and clade assignment (from TEsorter) were associated with each element.
- A histogram of LTR identity was generated for each clade, separated by superfamily.  
  (Figure: `01_LTR_Copia_Gypsy_cladelevel.png`)

### Guiding question: Are there differences in the number of full-length LTR-RTs between the clades?

Yes. Abundance of intact elements differs strongly by clade.

Copia superfamily:
- Ale: 14 intact elements
- Tork: 7
- Bianca: 6
- Ivana: 4
- SIRE: 1
- A single additional “Clade” entry: 1

Gypsy superfamily:
- Athila: 8 intact elements
- CRM: 8
- Retand: 7
- Reina: 3
- Tekay: 3
- A single additional “Clade” entry: 1

These values indicate that recent or preserved full-length copies are concentrated in a subset of specific clades (for example, Copia/Ale and Gypsy/Athila, CRM, Retand), rather than being evenly spread across all clades.

### Guiding question: Are there any clades with high percent identity (≈99–100%, i.e. young insertions) and clades with low percent identity (≈80–90%, i.e. old insertions)?

Yes. Distinct identity profiles are visible across clades:

- High identity (~0.99–1.00):  
  Elements whose paired LTRs are nearly identical are inferred to be recently inserted, because LTRs begin as identical at insertion time.  
  - Copia clade Ale shows a concentration of elements with LTR identity very close to 1.00.  
    → Indicates very recent Copia/Ale activity.  
  - Gypsy clade Reina also shows LTR-RTs with identity near 1.00.  
    → Indicates very recent Gypsy/Reina activity.

- Lower identity (~0.90–0.95 and below):  
  Elements with more divergent LTRs are interpreted as older insertions that have accumulated mutations over time.  
  - Gypsy clades Athila, CRM, and Retand include multiple elements with identities below ~0.95, in some cases around ~0.90.  
    → Indicates that these clades contributed older insertions.
  - Copia clades such as Ivana and Bianca include elements with identity values below ~0.95, suggesting an older layer of insertions for those clades.

Overall, both “young” and “old” signatures are present:
- Some clades show evidence of very recent bursts (Ale in Copia, Reina in Gypsy).
- Other clades represent more ancient activity (Athila / CRM / Retand in Gypsy; Bianca / Ivana in Copia).

This indicates multiple waves of LTR-RT amplification across evolutionary time, rather than a single historical event.

---

## 2. TE content summary from EDTA

TEs were annotated on the hifiasm primary assembly using EDTA. The following key output files were generated:

- `hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3`  
  (TE annotations on the assembly)
- `hifiasm.p_ctg.fa.mod.EDTA.TEanno.sum`  
  (summary of TE content)
- `hifiasm.p_ctg.fa.mod.EDTA.TElib.fa`  
  (consensus TE library)

The `.TEanno.sum` summary reports, for each TE superfamily, the number of annotated elements, total masked base pairs, and the fraction of the assembly represented by that family.

Selected values:
- Total interspersed repeats: ~15.9 Mbp masked, corresponding to ~12.59% of the assembly.
- Gypsy (LTR retrotransposons): ~2.19 Mbp masked (~1.73% of the genome).
- Copia (LTR retrotransposons): ~0.78 Mbp masked (~0.61%).
- Helitrons: ~2.51 Mbp masked (~1.99%).
- Mutator (TIR DNA transposons): ~2.05 Mbp masked (~1.62%).
- A large “unknown” repeat category: ~3.47% of the genome.
- Additional TIR superfamilies such as CACTA, PIF/Harbinger, hAT, and Tc1/Mariner are present at lower levels (<0.5% each).

### Guiding question: Which TE superfamily is the most abundant in the genome?

Several high-occupancy superfamilies contribute substantially to genome content:

- Among LTR retrotransposons, Gypsy elements contribute more total masked sequence (~1.73%) than Copia (~0.61%).
- Among cut-and-paste DNA transposons, Mutator is highly represented (~1.62%).
- Helitrons account for ~1.99%, similar in scale to Gypsy.
- The “unknown” class alone represents ~3.47% of the genome, making it the single largest labeled category in terms of masked proportion, although it is not resolved to a known superfamily.

In practical terms: Helitron, Gypsy, Mutator, and “unknown” repeats are the dominant contributors to repeat content.

### Guiding question: Are there any differences in TE content between the accessions?

Direct accessions-to-accessions comparison was not performed here.  
In a multi-accession design, differences would be assessed by comparing:
- Overall repeat load (percent of genome masked),
- Relative contributions of Gypsy vs Copia,
- Relative importance of DNA transposons (Mutator, CACTA, PIF/Harbinger, etc.),
- Size of the “unknown” fraction.

For the present assembly alone, interspersed repeats represent ~12.59% of the genome, with Gypsy, Helitrons, and Mutator standing out as major contributors.

---

## 3. TE spatial distribution across the genome

Genome-wide TE distribution was visualized using a circular layout based on the longest assembled scaffolds.  
The plot was generated using `circlize` in R (`06_circlize_density.sh`) and is provided as `02_TE_density_circlize.png`.

The circular ideogram shows scaffold-scale structure, and is intended to display TE density tracks for major TE superfamilies across each scaffold (e.g. Gypsy, Copia, TIR DNA transposons such as Mutator). In the current render, the scaffold ideogram is visible, while TE density rings are not fully drawn.

### Guiding question: Are there any regions with high TE density?

Plant genomes, including Arabidopsis-like assemblies, typically exhibit non-uniform TE density:
- Large blocks of high TE density are usually found in low-recombination, gene-poor regions (often pericentromeric or near centromere-like regions on large scaffolds).
- Other regions, especially gene-rich arms, carry fewer TEs.

Although not all TE density tracks rendered in the current figure, TE enrichment is expected to be localized rather than uniform, with “hotspots” along the largest scaffolds.

### Guiding question: Do the distributions of Gypsy, Copia, and TIR DNA transposons overlap, or are there differences?

LTR retrotransposons (Gypsy and Copia) and TIR DNA transposons (such as Mutator, CACTA) often show partially overlapping but distinct genomic preferences:
- Gypsy elements commonly accumulate in large, TE-rich blocks.
- Copia elements tend to be more patchy and may be less concentrated.
- TIR DNA transposons can show a different pattern, sometimes more dispersed and sometimes enriched in different scaffold regions than Gypsy.

Therefore, spatial distribution is not fully uniform across superfamilies: Gypsy tends to dominate specific repeat-rich regions, whereas Copia and TIR elements are not always maximally enriched in exactly the same locations.

---

## 4. Clade-level classification using TEsorter

To refine TE classification beyond “Copia” vs “Gypsy,” sequences were extracted from the final EDTA TE library (`...TElib.fa`) and classified using TEsorter (`rexdb-plant` database). The workflow was:

1. Extraction of sequences annotated as Copia-like and Gypsy-like into:
   - `Copia_sequences.fa`
   - `Gypsy_sequences.fa`

2. Clade-level classification with TEsorter, producing:
   - `Copia_sequences.fa.rexdb-plant.cls.tsv`
   - `Gypsy_sequences.fa.rexdb-plant.cls.tsv`

3. Aggregation of clade counts:
   - `Copia_clade_counts.tsv`
   - `Gypsy_clade_counts.tsv`

4. Visualization of those counts in `03_clade_counts.png`.

Observed clade counts:

**Copia superfamily**
- Ale: 14  
- Tork: 7  
- Bianca: 6  
- Ivana: 4  
- SIRE: 1  
- (generic “Clade” entry): 1  

→ Ale is the dominant Copia clade.

**Gypsy superfamily**
- Athila: 8  
- CRM: 8  
- Retand: 7  
- Reina: 3  
- Tekay: 3  
- (generic “Clade” entry): 1  

→ Athila and CRM are the two most represented Gypsy clades, followed by Retand.

An additional step attempted to map these clade assignments back to the actual genomic annotations in `TEanno.gff3` (script `09_clade_counts_from_TEanno.sh`), in order to produce `Copia_Gypsy_clade_counts_from_TEanno.tsv` and `04_clade_counts_from_TEanno.png`. The resulting table was empty in this run, so only a placeholder PDF (`04_clade_counts_from_TEanno.pdf`) is available. The clade-level interpretation therefore relies on `03_clade_counts.png` and the intact LTR-RT results.

### Guiding question: Using the final TEanno.gff3 file from EDTA and the clade classification of all TEs from TEsorter, can an estimate be provided for the number of Copia and Gypsy elements in each clade? What are the most abundant clades in the genome?

Clade-level estimates for Copia and Gypsy are summarized above. Key points:

- Copia superfamily is dominated by the **Ale** clade (14 sequences), followed by Tork (7) and Bianca (6).
- Gypsy superfamily is dominated by the **Athila** and **CRM** clades (8 each), followed by Retand (7).
- Reina and Tekay are present but at lower copy numbers (3 each).
- This indicates that only a subset of Copia/Gypsy clades accounts for most of the LTR retrotransposon landscape in this assembly.

---

## 5. TE dynamics

TE “dynamics” refers to timing and activity: which clades were active in the past vs which clades are (or were very recently) active.

Evidence for dynamics comes from:
1. The LTR identity distributions of intact LTR-RTs (`01_LTR_Copia_Gypsy_cladelevel.png`), which reflect element age.
2. The clade abundance summaries (`03_clade_counts.png`), which reveal which clades are producing the most intact copies.

### Guiding question: Can recent and ancient TE activity peaks be identified?

Yes.

- Recent activity:
  - Copia clade **Ale** shows many intact elements with LTR identity ≈1.00, consistent with very recent insertions.
  - Gypsy clade **Reina** shows intact elements with near-perfect LTR identity, also indicating recent insertion events.

- Older activity:
  - Gypsy clades such as **Athila**, **CRM**, and **Retand** include elements with lower LTR identity (~0.90–0.95), suggesting more ancient insertion waves that have accumulated mutations.
  - Copia clades such as **Bianca** and **Ivana** include elements with intermediate identity values (below ~0.95), which also points to older insertions.

Thus, evidence exists for both “ancient” and “recent” transposition peaks within the same genome.

### Guiding question: Are there differences in TE dynamics between the accessions studied in the group?

Cross-accession comparison was not performed here. In a multi-accession setting, differences would be evaluated by asking:
- Which clades currently show a strong high-identity peak (evidence of very recent expansion)?
- Which clades are mostly represented by older, diverged copies?
- Whether certain clades (for example, Ale or Athila) are specific to one accession or shared across several.

### Guiding question: How do the TE dynamics differ between Copia and Gypsy elements?

Clear differences are observed:

- Copia:
  - Strong recent activity is concentrated in a single dominant clade, **Ale**, which shows both high copy number (14 intact elements) and extremely high LTR-LTR identity (close to 1.00).
  - Other Copia clades (Tork, Bianca, Ivana) contribute fewer intact elements and often show more divergence, indicating older activity.

- Gypsy:
  - Activity is distributed across several major clades rather than a single dominant one.  
    Athila, CRM, and Retand each contribute many intact elements and include copies with lower LTR identity, consistent with multiple historical bursts.
  - At the same time, a Gypsy clade such as **Reina** shows high-identity insertions close to 1.00, indicating that Gypsy activity is not just ancient but also recent.

In summary:
- Copia elements show evidence for a focused, recent burst driven mainly by the Ale clade.
- Gypsy elements show evidence for both ancient expansions (Athila, CRM, Retand) and recent insertions (Reina), suggesting repeated waves of activity over time.

---

## 6. Summary

- Interspersed repeats cover ~12.59% of the assembly, based on EDTA annotation.
- Major contributors include Gypsy LTR retrotransposons (~1.73% of the genome), Helitrons (~1.99%), Mutator DNA transposons (~1.62%), and a large “unknown” fraction (~3.47%).
- TE content is not expected to be uniform along the genome; repeat-rich hotspots are typical in large scaffolds and pericentromeric-like regions.
- Full-length LTR-RT analysis shows both very recent insertions (LTR identity near 1.00) and more ancient insertions (LTR identity down to ~0.90 or below), indicating multiple temporal layers of TE activity.
- Copia superfamily is dominated by the Ale clade, which shows extremely young insertions.
- Gypsy superfamily is dominated by Athila, CRM, and Retand, which include older insertions, and also includes Reina, which shows very young insertions.
- These observations together indicate that TE activity in this genome is clade-specific, episodic, and ongoing.
