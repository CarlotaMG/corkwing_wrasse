# Corkwing Wrasse RNA-seq Analysis

This repository contains scripts and results for RNA-seq analysis of *Symphodus melops* (corkwing wrasse) from southern and western Norwegian populations and their hybrids. Individuals were experimentally exposed to three temperature treatments (12°C, 15°C, and 18°C) to assess transcriptional responses to temperature, population divergence, hybrid inheritance and misexpression.

---

## Data Availability

Raw RNA-seq data generated for this study are available at the European Nucleotide Archive (ENA) under accession:

**PRJEBXXXXX**.

Processed data supporting the findings of this study are available at Zenodo:

https://doi.org/XXXXX

---

## Analysis Overview

This chapter includes:

- Guided de novo transcriptome assembly using Trinity  
- Transcript annotation with Trinotate, EggNog, InterProScan and genome-based GFF integration  
- PCA and clustering to visualize sample structure  
- Model comparison to evaluate differential expression patterns and guide gene set selection  
- Differential expression analyses across temperature treatments and pedigrees using DESeq2  
- Selection of gene sets representing temperature-responsive, population-divergent, and hybrid inheritance  
- Functional enrichment of gene sets to identify associated biological processes and pathways  

---

## Workflow

1. **[Transcriptome Assembly](scripts/assembly/README.md)**  
2. **[Sample Clustering](scripts/sample_clustering/README.md)**  
3. **[Differential Expression](scripts/DE/README.md)**  
4. **[Annotation](scripts/annotation/README.md)**  
5. **[Functional Enrichment](scripts/functional_enrichment/README.md)**  

---

## Differential Expression Framework

Differential expression analysis identified gene expression patterns across temperature treatments and population origins.

Candidate gene sets were defined and grouped into three categories (referred to here as "tiers"):

- **Tier 1: Shared temperature-responsive genes**
  Genes consistently regulated by temperature across all origins. Defined by intersecting results from all pairwise temperature contrasts of the additive DE model.

    *Biological rationale*: given their consistent regulation across populations, these genes are expected to represent conserved components of the temperature response.

- **Tier 2: Divergence between West and South origins**
  Constitutive differences between origins using the additive DE model

    *Biological rationale*: represents baseline expression differences between populations, potentially reflecting underlying regulatory divergence.

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

### Working Environment
This analysis was conducted in a mixed computational environment combining HPC modules, containerized tools, and R-based analyses. Transcriptome assembly and annotation steps were performed each within their own Singularity container to ensure reproducibility.
Most scripts in this repository are modular and can be executed locally or on Unix-based systems. However, several computationally intensive steps were run on the Saga (Sigma2) HPC cluster using SLURM and may require similar resources to reproduce.

> SLURM job scripts used during analysis are not included in the repository to maintain clarity. Instead, modular scripts are documented with usage examples and can be integrated into SLURM workflows as needed.

This design reflects the actual workflow used during analysis and supports reproducibility across HPC systems.
This modular design also facilitates adaptation of individual components of the workflow to other RNA-seq studies, allowing reuse of scripts and analytical steps beyond this specific dataset.

#### HPC Modules
The following environment modules were loaded on Saga (Sigma2 cluster):
- FastQC/0.12.1-Java-11
- MultiQC/1.22.3-foss-2023b
- Trimmomatic/0.39-Java-11
- STAR/2.7.10b-GCC-11.3.0
- SAMtools/1.16.1-GCC-11.3.0
- BUSCO/5.5.0-foss-2022b
- HMMER/3.4-gompi-2023a
- BLAST+/2.14.1-gompi-2023a
- Python/3.10.8-GCCcore-12.2.0
- InterProScan/5.62-94.0-foss-2022a
#### Special tools
SignalP 6.0 (licensed DTU distribution) and DeepTMHMM (Apptainer image) were integrated into annotation workflows.
#### R-based analyses
All downstream analyses following assembly and annotation were conducted in R, with results documented in rendered HTML reports including visualizations, tables, and summary outputs

Details of container setup, module usage, external data resources and R sessions are documented in each section README.

---

## Project Structure

The repository is organized into modular components corresponding to each analysis step:

```
chapter1_rnaseq/
│
├── data/                     # Input data (metadata, raw and intermediate files)
│
├── resources/                # Reference genome, adapters, and external resources
│
├── results/                  # Outputs generated across analysis stages
│   ├── assembly/             # Transcriptome assembly and quantification outputs
│   ├── annotation/           # Functional annotation outputs (Trinotate, EggNOG, etc.)
│   ├── DE/                   # Differential expression results (tiers, tables and visualizations)
│   ├── sample_clustering/    # PCA and clustering results (plots and distance metrics)
│   └── functional_enrichment/ # Functional enrichment results across tiers
│
├── scripts/                  # Modular analysis workflows
│   ├── assembly/             # Transcriptome assembly
│   ├── annotation/           # Functional annotation (Trinotate, EggNOG, etc.)
│   ├── DE/                   # Differential expression analysis
│   ├── sample_clustering/    # PCA analysis
│   └── functional_enrichment/ # Functional enrichment
```
All paths in this chapter assume `chapter1_rnaseq/` as the working directory. Scripts are designed to be run from this location using relative paths to ensure reproducibility across systems.


---

## Results

Analysis reports, including quality control summaries and downstream results, are available at:

[carlotamg.github.io/corkwing_wrasse](https://carlotamg.github.io/corkwing_wrasse)

---

## Citation

If you use this workflow or results, please cite:
*Waiting on publication*
