# InterProScan (IPS) Annotation

## Overview

Functional annotation of the Trinity-assembled transcriptome was performed using multiple complementary approaches, including InterProScan.

InterProScan provides protein domain and functional annotation by integrating multiple databases (e.g., Pfam, SMART, PROSITE, SUPERFAMILY), and assigns Gene Ontology (GO) terms and pathway annotations based on conserved protein signatures.

This document provides script-level documentation for running InterProScan on the Trinity transcriptome in a modular and reproducible manner.

InterProScan was used to annotate predicted proteins with domain signatures, GO terms, and InterPro accessions.
IPS was run using the InterProScan module available on the Saga cluster.
Because the dataset was large, the peptide FASTA was processed in chunks using SLURM array jobs.
Per‑chunk IPS outputs were then merged into a single file for downstream Trinotate integration.

---

## Workflow

1. [Chunking](#1-chunking)
2. [IPS Execution](#2-ips-execution)
3. [Extraction](#4-extraction)

The execution environment used to run these steps is described in the [Execution Environment](#execution-environment) section.

---

## 1. Chunking
[ips_chunking.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/ips/ips_chunking.sh)

Splits a peptide FASTA file into smaller chunks without breaking FASTA records.
Before splitting, the script generates a cleaned version of the FASTA with all * characters removed, as these can cause IPS parsing errors.
Chunks are created based on a maximum number of sequences per chunk (default: 32,000), ensuring balanced IPS runtimes across array tasks.

#### Inputs
- Peptide FASTA file (e.g., longest_orfs.pep)
#### Outputs
- Cleaned FASTA file for provenance (e.g., longest_orfs.cleaned.pep)
- chunk_000/chunk_000.pep
- chunk_001/chunk_001.pep
- … one directory per chunk
#### Usage
```bash
bash ips_chunking.sh <pep_file> <chunks_dir> [chunk_size]
```
#### Example
```bash
bash scripts/annotation/ips/ips_chunking.sh \
    results/annotation/transdecoder/longest_orfs.pep \
    results/annotation/ips/chunks \
    32000
```

---

## 2. IPS Execution
[ips.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/ips/ips.sh)

Runs InterProScan on a single peptide FASTA chunk.
The script determines an output base name from the FASTA filename, uses node‑local scratch for temporary files, and produces both TSV (for Trinotate) and GFF3 outputs.
Output filenames are generated automatically from the chunk name.

#### Inputs
- Peptide FASTA file (e.g., chunk_000.pep)
#### Outputs
- chunk_000.tsv
- chunk_000.gff3

#### Usage
```bash
bash ips.sh <pep_fasta> <out_dir> <threads>
```

#### Example (SLURM array job)
```bash
# Format array index to match chunk naming
TASK_ID=$(printf "%03d" "$SLURM_ARRAY_TASK_ID")

# Define input FASTA and output directory for this chunk
CHUNK="results/annotation/ips/chunks/chunk_${TASK_ID}/chunk_${TASK_ID}.pep"
OUTDIR="results/annotation/ips/chunks/chunk_${TASK_ID}"

# Run IPS
bash scripts/annotation/ips/ips.sh \
    "$CHUNK" \
    "$OUTDIR" \
    "$SLURM_CPUS_PER_TASK"
```

After all array tasks finished, per‑chunk IPS outputs were merged:
```bash
cat results/annotation/ips/chunks/chunk_*/chunk_*.tsv \
    > results/annotation/ips/IPS_raw.tsv
sort -u results/annotation/ips/IPS_raw.tsv \
    > results/annotation/ips/IPS_merged.tsv
rm results/annotation/ips/IPS_raw.tsv
```

---

## 3. Extract
[ips_qc_extract.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/ips/ips_qc_extract.sh)
Extracts GO terms and InterPro accession counts from the merged IPS TSV file.
The script reads the IPS TSV (headerless) and generates two summary tables: GO terms per gene and InterPro accession counts.
#### Inputs
- IPS TSV file (e.g., IPS_merged.tsv)
Outputs
- ips_GO_by_gene.tsv
- ips_interpro_counts.tsv
#### Usage
```bash
bash ips_qc_extract.sh <IPS_TSV> <out_dir>
```
#### Example
```bash
bash scripts/annotation/ips/ips_qc_extract.sh \
    results/annotation/ips/IPS_merged.tsv \
    results/annotation/ips
```
