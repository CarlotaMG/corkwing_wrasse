# Corkwing Wrasse RNA-seq Analysis

This repository contains scripts and results for RNA-seq analysis of *Symphodus melops* (corkwing wrasse) from southern and western Norwegian populations and their hybrids. Individuals were experimentally exposed to three temperature treatments (12°C, 15°C, and 18°C) to assess transcriptional responses, local adaptation, and hybrid misregulation.

All scripts are organized under `scripts/` and results under `results/`. Rendered HTML reports from RMarkdown analyses are hosted via GitHub Pages at [carlotamg.github.io/corkwing_wrasse](https://carlotamg.github.io/corkwing_wrasse).

---

## Workflow

1. **Transcriptome Assembly**
   - [Assembly README](scripts/assembly/README.md)

2. **Annotation**
   - [Annotation README](scripts/annotation/README.md)
   - [Annotation Report](docs/annotation/annotation_report.html)

3. **Quality Control**
   - [FastQC Report](docs/qc/fastqc.html)
   - [MultiQC Report](docs/qc/multiqc.html)

4. **Sample Clustering**
   - [Sample Clustering README](scripts/sample_clustering/README.md)
   - [PCA Report](docs/sample_clustering/PCA_report.html)

5. **Differential Expression**
   - [DE README](scripts/DE/README.md)
   - [Model Comparison Report](docs/DE/de_model_comparison.html)
   - [Additive DE Report](docs/DE/additive_DE.html)

6. **Functional Enrichment**
   - [Functional Enrichment README](scripts/functional_enrichment/README.md)
   - [Enrichment Report](docs/functional_enrichment/enrichment_report.html)

---

## Differential Expression Tiers

To interpret temperature-dependent gene expression, we defined candidate sets across three tiers:

- **Tier 1: Shared temperature-responsive genes**  
  Genes consistently regulated by temperature across all origins. Defined by intersecting results from all pairwise temperature contrasts of the additive DE model.  
  *Biological rationale*: captures general thermal response, independent of population-specific effects.

- **Tier 2: Divergence between West and South origins**  
  Constitutive differences between origins, independent of temperature, using the additive model (~ origin + temperature).  
  *Biological rationale*: represents baseline expression differences that may reflect fixed genetic divergence.

- **Tier 2b: Local thermal adaptation candidates**  
  Overlap between Tier 2 constitutive differences and genes with significant interaction effects.  
  *Biological rationale*: strongest candidates for local adaptation, combining constitutive divergence with origin-specific plasticity.

- **Tier 3: Hybrid inheritance and misexpression**  
  Defined using the condition model at the isoform level. Categories include:
  - Misexpression (within-range and transgressive)
  - South-like inheritance
  - West-like inheritance  
  *Biological rationale*: provides insight into how parental expression programs are maintained or disrupted in hybrids, highlighting regulatory incompatibilities.

---

## Working Directory

All paths assume `chapter1_rnaseq/` as the working directory. Scripts are designed to be run from this location using relative paths to ensure reproducibility across systems.

---

## Computational Environment

- **HPC usage**: Computationally intensive steps (assembly, quantification) were run on Saga (Sigma2 cluster) using SLURM.  
- **Containers**: Trinity and Trinotate were run inside Singularity/Apptainer containers for reproducibility.  
- **Modules**: FastQC, MultiQC, STAR, SAMtools, BUSCO, HMMER, BLAST+, InterProScan, and others were loaded as environment modules.  
- **Special tools**: SignalP 6.0 (licensed DTU distribution) and DeepTMHMM (Apptainer image) were integrated into annotation workflows.

Details of container setup, module usage, and external data resources are documented in the [Assembly README](scripts/assembly/README.md) and [Annotation README](scripts/annotation/README.md).

---

## Citation

If you use this workflow or results, please cite:  
*Myhre de Gouveia, C. et al. (2026). Transcriptome assembly and temperature-dependent gene expression in corkwing wrasse.*

---
