# Corkwing Wrasse RNA-seq Analysis

This repository contains scripts and results for RNA-seq analysis of *Symphodus melops* (corkwing wrasse) from southern and western Norwegian populations and their hybrids. Individuals were experimentally exposed to three temperature treatments (12°C, 15°C, and 18°C) to assess transcriptional responses, local adaptation, hybrid inheritance and misexpression.

Rendered HTML reports from sample quality control and RMarkdown analyses are hosted via GitHub Pages at [carlotamg.github.io/corkwing_wrasse](https://carlotamg.github.io/corkwing_wrasse).

---

## Differential Expression Tiers

To interpret temperature-dependent gene expression, we defined candidate sets across three tiers:

- **Tier 1: Shared temperature-responsive genes** 
  Genes consistently regulated by temperature across all origins. Defined by intersecting results from all pairwise temperature contrasts of the additive DE model. 
 
	*Biological rationale*: given their consistent regulation across populations, these genes are expected to represent conserved components of the temperature response.

- **Tier 2: Divergence between West and South origins** 
  Constitutive differences between origins using the additive DE model 
  	
	*Biological rationale*: represents baseline expression differences that may reflect fixed genetic divergence.

- **Tier 2b: Local thermal adaptation candidates**
  Overlap between Tier 2 constitutive differences and genes with significant interaction effects.
 
	*Biological rationale*: strongest candidates for local adaptation, combining constitutive divergence with origin-specific plasticity.

- **Tier 3: Hybrid inheritance and misexpression**
  Defined using the condition DE model at the isoform level. Categories include:
  - Misexpression (within-range and transgressive)
  - South-like inheritance
  - West-like inheritance
 
	*Biological rationale*: provides insight into how parental expression programs are maintained or disrupted in hybrids, highlighting regulatory incompatibilities.

---

This chapter includes:

- Guided de novo transcriptome assembly using Trinity
- Transcript annotation with Trinotate, EggNog, InterProScan and Genome-Based GFF Integration
- PCA and clustering to visualize sample structure
- Model comparison to evaluate differential expression patterns and select models for gene extraction across tiers
- Differential expression analyses across temperature treatments and pedigrees using DESeq2
- Selection of tier gene sets to identify temperature-responsive, locally adapted, and misexpressed candidate genes
- Functional enrichment of tier gene sets to identify associated biological processes and pathways

---

## Workflow

1. **[Transcriptome Assembly](scripts/assembly/README.md)**

2. **[Sample Clustering](scripts/sample_clustering/README.md)**

3. **[Differencial Expression](scripts/DE/README.md)**

4. **[Annotation](scripts/annotation/README.md)**

5. **[Functional Enrichment](scripts/functional_enrichment/README.md)**

---

### Working Environment
This analysis was conducted in a mixed computational environment combining HPC modules, containerized tools, and R-based analyses. Transcriptome assembly and annotation steps were performed each within their own Singularity container to ensure reproducibility.
Most scripts in this repository are modular and can be executed locally or on Unix-based systems. However, several computationally intensive steps were run on the Saga (Sigma2) HPC cluster using SLURM and may require similar resources to reproduce.

> SLURM job scripts used during analysis are not included in the repository to maintain clarity. Instead, modular scripts are documented with usage examples and can be integrated into SLURM workflows as needed.

This design reflects the actual workflow used during analysis and supports reproducibility across HPC systems.

- **Containers**: Trinity(assembly) and Trinotate(annotation) were run inside Singularity/Apptainer containers for reproducibility.  
- **Modules**: FastQC, MultiQC, STAR, SAMtools, BUSCO, HMMER, BLAST+, InterProScan, and others were loaded as environment modules.  
- **Special tools**: SignalP 6.0 (licensed DTU distribution) and DeepTMHMM (Apptainer image) were integrated into annotation workflows.
- **R-based analyses**: All downstream analyses following assembly and annotation were conducted in R, with results documented in rendered HTML reports including visualizations, tables, and summary outputs

Details of container setup, module usage, external data resources and R sessions are documented in each section README. 

---

## Citation

If you use this workflow or results, please cite:
*Waiting on publication*

