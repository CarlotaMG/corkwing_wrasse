# Corkwing Wrasse Genomics and Transcriptomics

This repository accompanies a PhD project focused on the genomics and transcriptomics of the corkwing wrasse (*Symphodus melops*), a temperate marine fish. The project is organized into three chapters, each addressing a distinct aspect of evolutionary biology and molecular ecology — from gene expression and genomic divergence to population structure inferred from environmental DNA.

---

## Chapter 1: Temperature-Dependent Gene Expression

This chapter explores gene expression responses to temperature in Symphodus melops from southern and western Norwegian populations and their hybrids, based on RNA-seq data from fish exposed to three temperature conditions.
It includes:

- Guided de novo transcriptome assembly using Trinity
- Transcript annotation using Trinotate and genome-based GFF integration
- Comparison of annotation sources
- PCA and clustering to visualize sample structure
- Model comparison to evaluate differential expression patterns and select models for transcript extraction across tiers.
- Differential expression analysis across temperature and origin contrasts using DESeq2
- Tiered transcript selection to identify temperature-responsive, locally adapted, and misexpressed candidate genes
- Functional enrichment of tiered transcript sets to identify associated biological processes and pathways
 
See full details in the [Chapter 1 README](https://github.com/CarlotaMG/corkwing_wrasse/tree/main/chapter1_rnaseq).

---

## Chapter 2: Genomic Divergence, Selection, and Structural Variation *(planned)*

This chapter will explore genomic divergence and structural variation using whole-genome sequencing (WGS) data. Planned analyses include:

- Population structure and selection scans using WGS data
- Structural variant analysis using a chromosome-level reference genome
- Integration with DE genes from Chapter 1

This chapter is currently under development.

---

## Chapter 3: Population Genomics Using eDNA *(planned)*

This chapter will use environmental DNA (eDNA) to assess population structure and diversity across sampling sites. Planned analyses include:

- eDNA sampling and extraction
- Metabarcoding and bioinformatics processing
- Population-level analyses

This chapter is currently under development.

---

## Results

Reproducible analysis reports are available at:

https://carlotamg.github.io/corkwing_wrasse/

## Repository Structure

```
corkwing_wrasse/
├── chapter1_rnaseq/     # RNA-seq analysis and transcriptome assembly
├── chapter2_wgs/        # Whole-genome sequencing and variant analysis (planned)
├── chapter3_edna/       # eDNA-based population genomics (planned)
├── docs/                # Rendered HTML reports
├── LICENSE              # MIT license
└── README.md            # Project overview (this file)
```
## Resources

### Reference Genome

This project uses the publicly available *Symphodus melops* reference genome (fSymMel2) from the [Darwin Tree of Life Project](https://www.darwintreeoflife.org/) hosted by the Sanger Institute. The genome is scaffolded into 23 chromosomal pseudomolecules and is used throughout the project for guided de novo transcriptome assembly, annotation, mapping, and integration with genomic analyses.

**Citation**:
Howe *et al.* (2023). *The genome sequence of the corkwing wrasse, Symphodus melops*. *Wellcome Open Research*, 8:301. 
https://doi.org/10.12688/wellcomeopenres.19398.1

**Data Access**:
European Nucleotide Archive (ENA) Project: PRJEB58352
Genome Assembly Accession: CANSXB010000000
