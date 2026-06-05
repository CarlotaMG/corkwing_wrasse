# EggNOG Annotation

## Overview

Functional annotation of the Trinity-assembled transcriptome was performed using multiple complementary approaches, including EggNOG-mapper.

EggNOG provides orthology-based functional annotation, assigning genes to orthologous groups and predicting functional categories, pathways, and Gene Ontology (GO) terms based on evolutionary relationships.

This document provides script-level documentation for running EggNOG-mapper on the Trinity transcriptome in a modular and reproducible manner.

---

## Workflow

1. [Preparation](#1-preparation)
2. [EggNOG Annotation](#2-eggnog-annotation)
3. [Post-processing and Extraction](#3-post-processing-and-extraction)

The execution environment used to run these steps is described in the [Execution Environment](#execution-environment) section.

---

## 1. Preparation
[eggnog_prepare.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/eggnog/eggnog_prepare.sh)

Downloads and prepares all resources required by eggNOG‑mapper.
This script pulls the eggNOG‑mapper Apptainer image (if missing) and downloads the full eggNOG v5.0.2 database set, including DIAMOND, MMseqs2, PFAM, and taxonomy files.
It unpacks all components and ensures the database directory is complete before annotation.

#### Inputs
- Target path for the eggNOG‑mapper image (e.g., resources/eggnog-mapper.sif)
- Target directory for the eggNOG v5.0.2 database (e.g., resources/eggnog_db)
#### Outputs
- eggNOG‑mapper .sif container
- Unpacked eggNOG v5.0.2 database files (eggnog.db, eggnog.taxa.db, eggnog_proteins.dmnd, mmseqs/, pfam/)
#### Usage
```bash
bash eggnog_prepare.sh <sif_path> <db_dir>
```
#### Example
```bash
bash scripts/annotation/eggnog/eggnog_prepare.sh \
    resources/eggnog-mapper.sif \
    resources/eggnog_db
```

---

## 2. EggNOG Annotation
[eggnog_run.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/eggnog/eggnog_run.sh)

Runs eggNOG‑mapper on a peptide FASTA file using Apptainer.
The script stages the input FASTA and the DIAMOND database into node‑local scratch, then executes eggNOG‑mapper in DIAMOND mode with --dbmem enabled to load the DIAMOND database into memory for faster searches, and PFAM realignment activated.
Output filenames are generated using the user‑supplied prefix.
All .emapper.* outputs are written back to the specified output directory

#### Inputs
- eggNOG‑mapper .sif image (e.g., resources/eggnog-mapper.sif)
- eggNOG v5.0.2 database directory (e.g., resources/eggnog_db)
- Peptide FASTA file (e.g., results/annotation/transdecoder/longest_orfs.pep)
#### Outputs
- <prefix>.emapper.annotations (e.g., Trinity.emapper.annotations)
- <prefix>.emapper.hits (e.g., Trinity.emapper.hits)
- <prefix>.emapper.pfam (e.g., Trinity.emapper.pfam)
- <prefix>.emapper.seed_orthologs (e.g., Trinity.emapper.seed_orthologs)
#### Usage
```bash
bash eggnog_run.sh <sif> <db_dir> <pep_fasta> <out_prefix> <out_dir> <threads>
```
#### Example
```bash
bash scripts/annotation/eggnog/eggnog_run.sh \
    resources/eggnog-mapper.sif \
    resources/eggnog_db \
    results/annotation/transdecoder/longest_orfs.pep \
    Trinity \
    results/annotation/eggnog \
    12
```

---

## 3. Post-processing and Extraction
[eggnog_qc_extract.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/eggnog/eggnog_qc_extract.sh)

Extracts functional categories from the .emapper.annotations file.
The script detects the correct header line, identifies the GO/KO/KEGG/COG columns, and generates tidy per‑gene TSVs along with count tables.
Duplicate gene–annotation pairs are removed to ensure clean downstream integration.

#### Inputs
- .emapper.annotations file (e.g., Trinity.emapper.annotations)
#### Outputs
- eggnog_GO_by_gene.tsv
- eggnog_KO_by_gene.tsv
- eggnog_KEGG_pathway_by_gene.tsv
- eggnog_COG_by_gene.tsv
- eggnog_COG_counts.tsv
- eggnog_KO_counts.tsv
- eggnog_KEGG_pathway_counts.tsv
#### Usage
```bash
bash eggnog_qc_extract.sh <annotations> <out_dir>
```
#### Example
```bash
bash scripts/annotation/eggnog/eggnog_qc_extract.sh \
    results/annotation/eggnog/Trinity.emapper.annotations \
    results/annotation/eggnog
```

---

## Execution Environment

#### EggNOG‑mapper environment
eggNOG‑mapper is run inside an Apptainer container and requires the full eggNOG v5.0.2 database.

Container:
- `quay.io/biocontainers/eggnog-mapper:2.1.13--pyhdfd78af_2`
  (pulled as a `.sif` file by `eggnog_prepare.sh`)

Database:
- eggNOG v5.0.2 (downloaded and unpacked by `eggnog_prepare.sh`; includes DIAMOND, MMseqs2, PFAM, and taxonomy databases)

