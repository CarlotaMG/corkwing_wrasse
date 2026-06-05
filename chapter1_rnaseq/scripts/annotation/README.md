# Annotation

## Overview

This section describes the functional annotation workflow applied to the Trinity-assembled transcriptome. Multiple complementary annotation approaches were used to assign functional information to predicted transcripts, including transcriptome-based pipelines (EggNOG, InterProScan, Trinotate, SignalP, TMHMM), as well as genome-based annotation integrated via transcriptome–genome intersection.

The workflow integrates these sources through comparison and merging to produce a unified annotation dataset for downstream analyses.

---

## Directory Structure

The annotation workflow and its outputs are organised as follows:

```
scripts/annotation/
├── genome_based/      # Transcript–genome intersection and filtering
├── eggnog/            # EggNOG functional annotation pipeline
├── ips/               # InterProScan annotation pipeline
└── trinotate/         # Trinotate annotation (BLAST, Pfam, GO, SignalP, TMHMM)

results/annotation/
├── genome_based/      # Transcript–genome intersection outputs and summaries
├── eggnog/            # EggNOG annotation results
├── ips/               # InterProScan outputs
└── trinotate/         # Trinotate outputs
    ├── go_extraction/     # Extracted GO annotations
    ├── signalp/           # Signal peptide predictions
    ├── tmhmm/             # Transmembrane helix predictions
    └── trinotate_final/   # Final Trinotate annotation report
```
Most directories are created and populated by the corresponding scripts during execution, although some may need to be created beforehand. The directory structure is provided here to ensure that the workflow can be reproduced if needed. Script usage examples below illustrate the expected input and output paths.

All scripts are designed to be executed from the `chapter1_rnaseq/` directory, and all paths shown here are relative to that location.

---

## Workflow Structure

The annotation workflow consists of three main components:

1. Genome-based annotation  
2. Transcriptome-based annotation  
3. Annotation comparison and integration  

---
## 1. Genome-based Annotation

### Genome annotation

Genome-based annotation was generated as part of this project using a custom genome annotation pipeline integrating RNA-seq data from this study within an evidence-based framework (Evidence Modeler, EVM) for gene model prediction. This pipeline was conducted separately and is not included in this repository.

The resulting annotation includes gene models and corresponding predicted protein sequences, along with functional annotations such as InterPro, Pfam, PANTHER, Gene Ontology (GO), and UniProt identifiers.

The annotation was further processed by aligning the Trinity transcriptome to the reference genome, standardising FASTA headers for compatibility, and intersecting transcript alignments (BAM) with genome annotation features (GFF). The resulting overlaps were processed and summarised based on the coverage of annotated mRNA models by assembled transcripts, providing a quantitative measure of agreement between annotated gene models and transcript reconstructions.

The genome-based annotations are available at:
https://doi.org/XXXXX

Detailed processing steps and scripts are described in:
[scripts/annotation/genome_based/README.md](scripts/annotation/genome_based/README.md)
---

## 2. Transcriptome-based annotation

Functional annotation of the Trinity transcriptome was performed using multiple complementary approaches, each providing distinct sources of functional information:

- `scripts/annotation/trinotate/README.md` — integrates homology searches, protein domain identification, and structural features into a unified annotation framework  
- `scripts/annotation/eggnog/README.md` — assigns orthology-based functional annotations, including GO terms, KEGG pathways, and COG categories  
- `scripts/annotation/ips/README.md` — identifies conserved protein domains and associated functional annotations using InterProScan  

Each method was executed independently and generates complementary annotation evidence for downstream integration.

---

## 3. Annotation comparison and integration

Annotation outputs from all sources (genome-based annotation, Trinotate, EggNOG, and InterProScan) were processed and integrated into a unified annotation framework for downstream analyses.

Details of the integration workflow, including inputs and outputs, are described in:
`scripts/annotation/integration/README.md`

The integration and analysis are implemented in:
`scripts/annotation/annotations.Rmd`

This step includes:

- Harmonisation of transcript and gene identifiers across annotation sources  
- Comparison of annotation coverage and overlap  
- Integration of functional annotations into a combined dataset  

