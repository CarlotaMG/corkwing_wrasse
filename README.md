# Corkwing Wrasse Genomics and Transcriptomics

This repository accompanies a PhD project focused on the genomics and transcriptomics of the corkwing wrasse (*Symphodus melops*), a temperate marine fish. The project is organized into three chapters, each addressing a distinct aspect of evolutionary biology and molecular ecology — from gene expression and genomic divergence to population structure inferred from environmental DNA.

---

## Chapter 1: Temperature-Dependent Gene Expression

This chapter investigates gene expression responses to temperature across pedigrees (southern, western, and hybrid origins in Norway) using RNA-seq data. 
It includes:

- Guided de novo transcriptome assembly using Trinity
- Transcript annotation using Trinotate and genome-based GFF integration
- PCA and clustering to visualize sample structure
- Model comparison to evaluate differential expression patterns and select models for transcript extraction across tiers.
- Differential expression analysis across temperature and origin contrasts using DESeq2
- Tiered transcript selection to identify temperature-responsive, locally adapted, and misexpressed candidate genes
- Functional enrichment of tiered transcript sets to identify associated biological processes and pathways
 
See the Chapter 1 [README](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/README.md) for full details.

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

## Documentation

Rendered HTML reports are available in the `docs/` folder and via GitHub Pages:

🔗 https://carlotamg.github.io/corkwing_wrasse/

---

- **DE Model Comparison** - Compares condition, additive, and interaction models. *(Generated from `scripts/DE_model_comparison.Rmd`)*
- **Additive Model DE** - Performs differential expression analyses using the additive model. *(Generated from `scripts/additive_DE.Rmd`)*

=======
## Repository Structure

corkwing_wrasse/
├── chapter1_rnaseq/     # RNA-seq analysis and transcriptome assembly
├── chapter2_wgs/        # Whole-genome sequencing and variant analysis (planned)
├── chapter3_edna/       # eDNA-based population genomics (planned)
├── docs/                # Rendered HTML reports
├── LICENSE              # MIT license
└── README.md            # Project overview (this file)

