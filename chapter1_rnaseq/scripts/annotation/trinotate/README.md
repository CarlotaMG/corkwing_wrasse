# Trinotate Annotation 

Functional annotation of the Trinity-assembled transcriptome was performed using multiple complementary approaches, with the Trinotate pipeline providing integrated annotation based on homology, protein domains, and structural features.

Trinotate combines evidence from ORF prediction, sequence similarity searches, protein domain identification, signal peptide prediction, and transmembrane region detection. These features are integrated into a unified SQLite database, enabling consistent annotation and downstream querying.

This document provides detailed script-level documentation for each step of the Trinotate annotation workflow, with scripts designed to be modular and to accept command-line arguments, allowing them to be executed independently or adapted for related analyses.

---

## Workflow

1. [TransDecoder LongOrfs](#1-transdecoder-longorfs)
2. [BLASTP](#2-blastp)
3. [Pfam](#3-pfam)
4. [TransDecoder Predict](#4-transdecoder-predict)
5. [BLASTX](#5-blastx)
6. [SignalP](#6-signalp)
7. [DeepTMHMM](#7-deeptmhmm)
8. [Trinotate Integration](#8-trinotate-integration)
9. [GO Term Extraction](#9-go-term-extraction)

The execution environment used to run these steps is described in the [Execution Environment](#execution-environment) section.

---

## Directory Structure


The outputs of the Trinotate workflow are organised as follows:

```
results/annotation/trinotate/
├── transdecoder_longorfs/    # ORF candidates (initial longest ORFs)
├── blastp/                   # Protein homology results (Swiss-Prot)
├── pfam/
│   └── chunks/               # Chunked outputs (SLURM array jobs)
├── transdecoder_predict/     # Final ORF predictions
├── blastx/
│   └── chunks/               # Chunked outputs (SLURM array jobs)
├── signalp/
│   └── chunks/               # Chunked outputs (SLURM array jobs)
├── tmhmm/
│   └── chunks/               # Chunked outputs (SLURM array jobs)
├── trinotate_data/           # External annotation databases
├── trinotate_final/          # Integrated Trinotate outputs
└── go_extraction/            # GO annotation summaries
```

Most directories are created and populated by the corresponding scripts during execution, although some may need to be created beforehand. The directory structure is provided here to ensure that the workflow can be reproduced if needed. Script usage examples below illustrate the expected input and output paths.

Several steps (BLASTX, Pfam, SignalP, and DeepTMHMM) are executed in parallel using SLURM array jobs, producing chunked outputs within the respective tool directories.

All scripts are designed to be executed from the `chapter1_rnaseq/` directory, and all paths shown here are relative to that location.

---

## 1. TransDecoder LongOrfs
[transdecoder_longorfs.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/transdecoder_longorfs.sh)

Identifies long open reading frames (ORFs) in Trinity-assembled transcripts and links them to gene IDs. The script accepts four arguments: the transcriptome FASTA file, the gene-transcript mapping file, Trinotate's Singularity image, and the output directory.
##### Inputs
- Trinity transcriptome FASTA file (Trinity-GG.fasta)
- Gene-to-transcript mapping file (Trinity-GG.fasta.gene_trans_map)
##### Outputs
- Predicted peptide sequences (longest_orfs.pep)
- ORF coordinates (longest_orfs.gff3)
##### Usage
```bash
bash scripts/annotation/trinotate/transdecoder_longorfs.sh \
<transcriptome_fasta> \
<gene_trans_map> \
<singularity_image> \
<output_dir>
```
##### Example
```bash
bash scripts/annotation/trinotate/transdecoder_longorfs.sh \
results/assembly/trinity/Trinity-GG.fasta \
results/assembly/trinity/Trinity-GG.fasta.gene_trans_map \
resources/trinotate.v4.0.2.simg \
results/annotation/trinotate/transdecoder_longorfs
```

---

## 2. BLASTP
[blastp.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/blastp.sh)

Runs blastp on predicted peptide sequences against the UniProtKB/Swiss-Prot protein database using a Singularity container. The script takes a peptide FASTA file, a Singularity image, a desired filename for the Swiss-Prot FASTA file, and an output directory. If the UniProtKB/Swiss-Prot FASTA file is missing, the script downloads and decompresses it, then uses it to build a BLAST database with makeblastdb. It subsequently runs blastp to align the peptide sequences against this database.
##### Inputs
- Predicted peptide sequences (e.g., longest_orfs.pep)
##### Outputs
- Top 5 hits per query in tabular BLAST format (blastp.outfmt6)
- Swiss-Prot protein database FASTA file (e.g., uniprot_sprot_2025_10.fasta)
- BLAST database index files (.pin, .phr, .psq)
##### Usage
```bash
bash scripts/annotation/trinotate/blastp.sh \
<pep_file> \
<singularity_image> \
<fasta_file> \
<output_dir>
```
##### Example
```bash
bash scripts/annotation/trinotate/blastp.sh \
results/annotation/trinotate/transdecoder_longorfs/longest_orfs.pep \
resources/trinotate.v4.0.2.simg \
resources/uniprot_sprot/uniprot_sprot_2025_10.fasta \
results/annotation/trinotate/blastp
```

---

## 3. Pfam
[pfam.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/pfam.sh)

Runs hmmscan on predicted peptide sequences to identify conserved protein domains. The script takes a peptide FASTA file, a Singularity image, a desired filename for the Pfam-A HMM file, an output directory, and the number of threads to use. If the HMM file is missing, it is downloaded and decompressed. The script then builds the HMM database using hmmpress and scans the peptide sequences with hmmscan.
##### Inputs
- Predicted peptide sequences (e.g., longest_orfs.pep)
##### Outputs
- Domain table output (pfam.domtblout)
- Pfam-A HMM file (e.g., Pfam-A_2025_10.hmm)
- Pfam HMM index files (.h3f, .h3i, .h3m, .h3p)
##### Usage
```bash
bash scripts/annotation/trinotate/pfam.sh \
<pep_file> \
<singularity_image> \
<pfam_hmm> \
<output_dir> \
<threads>
```
##### Example
```bash
bash scripts/annotation/trinotate/pfam.sh \
results/annotation/trinotate/transdecoder_longorfs/longest_orfs.pep \
resources/trinotate.v4.0.2.simg \
resources/pfam/Pfam-A_2025_10.hmm \
results/annotation/trinotate/pfam \
16
```

##### Post-run
```bash
cat results/annotation/trinotate/pfam/chunks/*/*.domtblout > /results/annotation/trinotate/pfam/pfam_merged.domtblout
```

---

## 4. TransDecoder Predict
[transdecoder_predict.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/transdecoder_predict.sh)

Runs TransDecoder.Predict to identify the most likely coding regions in the Trinity transcriptome using Trinotate’s Singularity image.
This step uses ORF hinting, incorporating both BLASTP and Pfam results to retain ORFs supported by homology evidence.
Because ORF hinting requires BLASTP and Pfam results, this step is executed after BLASTP and Pfam.
The script also symlinks the outputs from the TransDecoder.LongOrfs step into the working directory so that TransDecoder.Predict can access the ORF candidates.

#### Inputs
- Trinity transcriptome FASTA file (e.g., Trinity-GG.fasta)
- BLASTP results used as ORF hints (blastp.outfmt6)
- Pfam domain table used as ORF hints (pfam_merged.domtblout)
- LongOrfs outputs (longest_orfs.pep, longest_orfs.gff3) — symlinked automatically
#### Outputs
- Final predicted peptide sequences (transdecoder.pep)
- Predicted coding sequences (transdecoder.cds)
- Coding‑region annotations in GFF3 format (transdecoder.gff3)
- ORF coordinates in BED format (transdecoder.bed)
#### Usage
```bash
bash transdecoder_predict.sh \
    <fasta_file> \
    <singularity_image> \
    <blastp_hits> \
    <pfam_hits> \
    <output_dir> \
    <threads>
```
#### Example
```bash
bash scripts/annotation/trinotate/transdecoder_predict.sh \
    results/assembly/trinity/Trinity-GG.fasta \
    resources/trinotate.v4.0.2.simg \
    results/annotation/trinotate/blastp/blastp.outfmt6 \
    results/annotation/trinotate/pfam/pfam_merged.domtblout \
    results/annotation/trinotate/transdecoder_predict \
    2
```

---

## 5. BLASTX

BLASTX was used to search the Trinity transcriptome against the SwissProt protein database using the BLAST+ module available on the Saga cluster. Because the dataset was large, the transcriptome FASTA was processed in chunks using SLURM array jobs. Per‑chunk BLASTX outputs were then merged into a single file for downstream integration into Trinotate.

[blastx_chunking.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/blastx_chunking.sh)

Splits a large transcriptome FASTA file into smaller chunks without breaking FASTA records. Chunk size is controlled by a maximum byte threshold.

#### Inputs
- Transcriptome FASTA file (e.g., Trinity-GG.fasta)
#### Outputs
- chunk_000/chunk_000.fasta
- chunk_001/chunk_001.fasta
- … one directory per chunk
#### Usage
```bash
bash blastx_chunking.sh <fasta_file> <output_dir> <max_bytes>
```
#### Example
```bash
bash scripts/annotation/trinotate/blastx_chunking.sh \
    results/assembly/trinity/Trinity-GG.fasta \
    results/annotation/trinotate/blastx/chunks \
    5000000
```

⸺

[blastx_localcopy.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/blastx_localcopy.sh)

Runs BLASTX on a single transcript FASTA chunk. If node‑local scratch storage is available, the BLAST database is copied there for faster access, avoiding I/O bottlenecks.

#### Inputs
- Transcript FASTA (e.g., chunk_002.fa)
- SwissProt BLAST database (e.g., uniprot_sprot_2025_10)
#### Outputs
- BLASTX results for the chunk (e.g., chunk_002.blastx)
#### Usage
```bash
bash blastx_localcopy.sh <fasta_chunk> <blast_db> <output_file> <threads>
```
#### Example(SLURM array job)
```bash
# Format array index to match chunk naming
TASK_ID=$(printf "%03d" "$SLURM_ARRAY_TASK_ID")

# Define input FASTA and output file for this chunk
CHUNK="results/annotation/trinotate/blastx/chunks/chunk_${TASK_ID}/chunk_${TASK_ID}.fa"
OUT="results/annotation/trinotate/blastx/chunks/chunk_${TASK_ID}/chunk_${TASK_ID}.blastx"
DB="resources/uniprot_sprot/uniprot_sprot_2025_10"

# Run BLASTX
bash scripts/annotation/trinotate/blastx_localcopy.sh \
    "$CHUNK" \
    "$DB" \
    "$OUT" \
    "$SLURM_CPUS_PER_TASK"
```
After all array tasks finished, all per‑chunk BLASTX outputs were merged into a single file:
```bash
cat results/annotation/trinotate/blastx/chunks/*/*.blastx \
    > results/annotation/trinotate/blastx/merged.blastx
```

---

## 6. SignalP
SignalP 6.0 was used to predict signal peptides in the translated ORFs. Because SignalP is not included in the Trinotate container due to licensing restrictions, and no SignalP module is available on Saga (Sigma2) cluster, the tool was installed in a dedicated Python virtual environment (see Working Environment section above). The peptide FASTA was processed in chunks using SLURM array jobs, and results were merged into a single Trinotate‑compatible output file.

[signalp_prepare.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/signalp_prepare.sh)

Creates a dedicated Python virtual environment for SignalP 6.0, installs the DTU package, and copies the model weights into the correct location inside the environment.

#### Inputs
- Base directory containing the unpacked SignalP package (e.g., signalp6_fast/signalp-6-package)
#### Outputs
- The fully configured virtual environment at <base_dir>/env
#### Usage
```bash
bash signalp_prepare.sh <base_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/signalp_prepare.sh resources/signalp
```
⸺

[signalp_chunking.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/signalp_chunking.sh)

Splits a large peptide FASTA file into smaller chunks (~10,000 sequences each) to enable parallel execution on the HPC.

#### Inputs
- Peptide FASTA file (e.g., longest_orfs.pep)
#### Outputs
- chunk_000/chunk_000.pep
- chunk_001/chunk_001.pep
- … one directory per chunk
#### Usage
```bash
bash signalp_chunking.sh <pep_file> <output_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/signalp_chunking.sh \
    results/annotation/trinotate/transdecoder_longorfs/longest_orfs.pep \
    results/annotation/trinotate/signalp/chunks
```
⸺

[signalp.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/signalp.sh)

Runs SignalP 6.0 on a single peptide FASTA chunk inside the SignalP virtual environment.

#### Inputs
- Path to the SignalP virtual environment (e.g., resources/signalp/env)
- Peptide FASTA chunk (e.g., chunk_002.pep)
#### Outputs
- SignalP prediction results (prediction_results.txt)
- SignalP region annotations (region_output.gff3)
#### Usage
```bash
bash signalp.sh <env_dir> <pep_fasta> <output_dir> <threads>
```
#### Example(SLURM array job)
```bash
# List all chunk FASTA files
CHUNKS=(results/annotation/trinotate/signalp/chunks/chunk_*/chunk_*.pep)

# Select the chunk for this array index
PEP_FASTA=${CHUNKS[$SLURM_ARRAY_TASK_ID]}

# Define output directory for this chunk
OUT_DIR=$(dirname "$PEP_FASTA")/signalp_out

# Run SignalP
bash scripts/annotation/trinotate/signalp.sh \
    resources/signalp/env \
    "$PEP_FASTA" \
    "$OUT_DIR" \
    $SLURM_CPUS_PER_TASK
```

⸺

[signalp_merge.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/signalp_merge.sh)

Combines all per‑chunk SignalP outputs into a single merged file suitable for loading into Trinotate.
This script expects each chunk directory to contain a signalp_out/ folder produced by signalp.sh.

#### Inputs
- Directory containing chunk folders with SignalP output (e.g., signalp/chunks/)
- Directory for merged output files (e.g., signalp/)
#### Outputs
- Merged SignalP prediction results (signalp_merged.prediction_results.txt)
- Merged SignalP gff3 outputs (signalp_merged.output.gff3)
#### Usage
```bash
bash signalp_merge.sh <chunks_dir> <merged_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/signalp_merge.sh \
    results/annotation/trinotate/signalp/chunks \
    results/annotation/trinotate/signalp
```

---

## 7. DeepTMHMM
DeepTMHMM was used to predict transmembrane helices in the translated ORFs. Because the dataset was large and the workflow was executed on the Saga cluster, the peptide FASTA was processed in chunks using SLURM array jobs. Per‑chunk outputs were then merged and converted into a standardized GFF3 file for downstream processing.

[tmhmm_chunking.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/tmhmm_chunking.sh)

Splits a large peptide FASTA file into smaller chunks without breaking FASTA records.
Chunk size is controlled by a maximum byte threshold.

#### Inputs
- Peptide FASTA file (e.g., longest_orfs.pep)
- Maximum chunk size in bytes (e.g., 5 000 000)
#### Outputs
- chunk_000/chunk_000.pep
- chunk_001/chunk_001.pep
- … one directory per chunk
#### Usage
```bash
bash tmhmm_chunking.sh <pep_file> <output_dir> <max_bytes>
```
#### Example
```bash
bash scripts/annotation/trinotate/tmhmm_chunking.sh \
    results/annotation/trinotate/transdecoder_longorfs/longest_orfs.pep \
    results/annotation/trinotate/tmhmm/chunks \
    5000000
```

⸺

[deeptmhmm_exec.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/deeptmhmm_exec.sh)

Runs DeepTMHMM on a single peptide FASTA chunk using an Apptainer container (see Working Environment section above).
The script creates a job‑specific directory on node‑local scratch ($LOCALSCRATCH if allocated, otherwise /tmp) and binds this directory into the container for DeepTMHMM’s temporary files and embeddings

#### Inputs
- Peptide FASTA chunk (e.g., chunk_002.pep)
- DeepTMHMM Apptainer image (e.g., deeptmhmm_offline.sif)

#### Outputs
- Predicted topologies (predicted_topologies.3line)
- Transmembrane region annotations (TMRs.gff3)
- (Optional) embeddings if PURGE_EMBEDDINGS=0
#### Usage
```bash
bash deeptmhmm_exec.sh <pep_fasta> <output_dir> <image.sif>
```
#### Example(SLURM array job)
```bash
# Format array index to match chunk naming
TASK_ID=$(printf "%03d" "$SLURM_ARRAY_TASK_ID")

# Define input FASTA and output directory for this chunk
PEP_FILE="results/annotation/trinotate/tmhmm/chunks/chunk_${TASK_ID}/chunk_${TASK_ID}.pep"
OUT_DIR="results/annotation/trinotate/tmhmm/chunks/chunk_${TASK_ID}"

# Run DeepTMHMM
bash scripts/annotation/trinotate/deeptmhmm_exec.sh \
    "$PEP_FILE" \
    "$OUT_DIR" \
    resources/deeptmhmm/deeptmhmm_offline.sif
```

After all array tasks finished, all per‑chunk DeepTMHMM outputs were merged into a single file:
```bash
cat results/annotation/trinotate/tmhmm/chunks/*/deeptmhmm_out/biolib_results/TMRs.gff3 \
    > results/annotation/trinotate/tmhmm/tmhmm_all.gff3
```

⸺

[clean_deeptmhmm.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/clean_deeptmhmm.sh)

Converts the merged DeepTMHMM output into a valid 9‑column GFF3 file.
This script removes repeated headers, filters out non‑TMhelix states, and adds stable feature IDs and metadata.

#### Inputs
- Merged DeepTMHMM output (e.g., tmhmm_all.gff3)
#### Outputs
- Cleaned GFF3 file containing only TMhelix features (e.g., tmhmm_clean.gff3)
#### Usage
```bash
bash clean_deeptmhmm.sh <input_gff> <output_gff>
```
#### Example
```bash
bash scripts/annotation/trinotate/clean_deeptmhmm.sh \
    results/annotation/trinotate/tmhmm/tmhmm_all.gff3 \
    results/annotation/trinotate/tmhmm/tmhmm_clean.gff3
```

> **Note:** DeepTMHMM output is not compatible with the TMHMM 2.0 format expected by Trinotate, so it cannot be loaded directly into the Trinotate database. A cleaned GFF3 file was generated with the intention of integrating DeepTMHMM predictions into the final Trinotate report, but this integration did not succeed. The DeepTMHMM predictions will instead be incorporated after Trinotate’s report generation during the downstream analysis stage.

---

## 8. Trinotate Integration
[trinotate_load.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/trinotate_load.sh)

Loads all functional‑annotation evidence into a unified Trinotate SQLite database and generates the main Trinotate annotation report. This script integrates all upstream results (TransDecoder, BLASTP, BLASTX, Pfam, SignalP, DeepTMHMM) into the database and runs entirely inside the Trinotate Singularity container. It performs database initialization, evidence loading, dynamic report‑flag detection, and report generation.
This script assumes that the manually required Trinotate data resources (EggNOG and Rfam) have already been prepared in data_dir, as described in the Working Environment section.
#### Inputs
- Trinotate Singularity image (trinotate.v4.0.2.simg)
- Gene‑to‑transcript mapping file (Trinity-GG.fasta.gene_trans_map)
- Trinity transcriptome FASTA (Trinity-GG.fasta)
- Predicted peptides from TransDecoder (Trinity-GG.fasta.transdecoder.pep)
- BLASTP results (blastp.outfmt6)
- BLASTX results (merged.blastx)
- Pfam domain table (pfam_merged.domtblout)
- SignalP predictions (signalp_merged.prediction_results.txt)
- DeepTMHMM predictions (tmhmm_clean.gff3)
#### Outputs
- Trinotate SQLite database (Trinotate.sqlite)
- Final annotation report (trinotate_annotation_report.xls)
#### Usage
```bash
bash scripts/annotation/trinotate/trinotate_load.sh \
    <singularity_image> \
    <gene_trans_map> \
    <transcripts_fasta> \
    <pep_file> \
    <blastp_outfmt6> \
    <blastx_out> \
    <pfam_domtblout> \
    <signalp_results> \
    <tmhmm_gff3> \
    <output_dir> \
    <data_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/trinotate_load.sh \
    resources/trinotate.v4.0.2.simg \
    results/assembly/trinity/Trinity-GG.fasta.gene_trans_map \
    results/assembly/trinity/Trinity-GG.fasta \
    results/annotation/trinotate/transdecoder_predict/Trinity-GG.fasta.transdecoder.pep \
    results/annotation/trinotate/blastp/blastp.outfmt6 \
    results/annotation/trinotate/blastx/merged.blastx \
    results/annotation/trinotate/pfam/pfam_merged.domtblout \
    results/annotation/trinotate/signalp/signalp_merged.prediction_results.txt \
    results/annotation/trinotate/tmhmm/tmhmm_clean.gff3 \
    results/annotation/trinotate/trinotate_final \
    results/annotation/trinotate/trinotate_data
```

---

## 9. GO Term Extraction
[go_finalize.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/go_finalize.sh)

Extracts Gene Ontology (GO) assignments from the Trinotate annotation report and generates direct and ancestral GO term tables, GO‑Slim summaries, and a Trinotate report summary.
This script uses Trinotate’s built‑in GO utilities inside the Singularity container.

#### Inputs
- Trinotate Singularity image (trinotate.v4.0.2.simg)
- Trinotate annotation report (trinotate_annotation_report.xls)
#### Outputs
- GO term tables
Direct and ancestral GO assignments per gene, written to the GO output directory
(e.g., trinotate_GO_by_gene.tsv)
- GO‑Slim summaries
High‑level GO category summaries derived from the gene‑level GO tables, written to the GO output directory
(e.g., trinotate_GO_by_gene.slim.tsv)
- Trinotate summary files
Summary statistics and functional category counts generated by trinotate_report_summary.pl, written to the Trinotate final results directory
(e.g., trinotate_summary.GO, trinotate_summary.cXp_summary.html)
#### Usage
```bash
bash scripts/annotation/trinotate/go_finalize.sh \
    <singularity_image> \
    <trinotate_xls> \
    <go_output_dir> \
    <trinotate_final_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/go_finalize.sh \
    resources/trinotate.v4.0.2.simg \
    results/annotation/trinotate/trinotate_final/trinotate_annotation_report.xls \
    results/annotation/trinotate/go_extraction \
    results/annotation/trinotate/trinotate_final
```

---

## Execution environment

#### Singularity Container for Trinotate
The container used for transcript annotation was downloaded on October 25, 2025 from the Broad Institute's Trinity resource server. It included Trinotate v4.0.2, along with supporting tools for transcript annotation and database integration.

The container was downloaded from the Broad Institute's Trinity resource server using:
```bash
wget https://data.broadinstitute.org/Trinity/TRINOTATE_SINGULARITY/trinotate.v4.0.2.simg \
-O resources/trinotate.v4.0.2.simg
```

Scripts using Trinotate are designed to run inside the container using:
```bash
singularity exec --bind $(pwd):$(pwd) resources/trinotate.v4.0.2.simg <command>
```

For more information, see [Trinotate GitHub repository](https://github.com/Trinotate/Trinotate).

#### SignalP 6.0 Environment
SignalP 6.0 is not included in the Trinotate container due to licensing restrictions, and no SignalP module is available on the Saga (Sigma2) cluster. Because the tool requires a licensed DTU distribution and specific Python dependencies (including NumPy <2), it was installed in a dedicated Python virtual environment.
The SignalP 6.0 archive (signalp-6.0i.fast.tar.gz) was obtained from the DTU Health Tech download portal after accepting the academic license agreement and unpacked into a local directory. The unpacked DTU package (signalp6_fast/signalp-6-package) is used by the installation script:
```bash
scripts/annotation/trinotate/signalp_prepare.sh
```

#### DeepTMHMM Environment
Trinotate was originally designed to integrate TMHMM, not DeepTMHMM. However, TMHMM is no longer maintained and has been superseded by DeepTMHMM, which provides substantially improved accuracy using modern deep‑learning methods. For this reason, DeepTMHMM was used instead of TMHMM in this workflow.
DeepTMHMM is implemented in Python and depends on PyTorch and OpenProtein, which are not available inside the Trinotate container and cannot be added without rebuilding it from scratch. Although the DeepTMHMM codebase is open‑source (MIT license), the Docker images commonly used to run it cannot be redistributed inside third‑party containers such as Trinotate. In addition, Saga does not allow Docker pulls or Docker‑based builds, so the Apptainer image must be created on a local machine and transferred to the cluster.
The DeepTMHMM Apptainer image used in this project was built locally from the Docker image docker.io/biswasaneel/deeptmhmm:latest using Apptainer’s Docker bootstrap mechanism (January 2026) and then copied to Saga for offline use. To reproduce the environment, the image can be rebuilt using:
```bash
apptainer build deeptmhmm_offline.sif docker://docker.io/biswasaneel/deeptmhmm:latest
```

#### Trinotate Data Resources
Trinotate requires several external data sources for functional annotation.
The data resources needed for the final Trinotate loading and report‑generation were stored in a dedicated directory:
```bash
DATA_DIR=results/annotation/trinotate/trinotate_data/
```
All outputs from the final Trinotate loading and report‑generation step were written to the following directory:
```bash
OUT_DIR=results/annotation/trinotate/trinotate_final/
```
During annotation, the Trinotate container automatically populates most required databases into DATA_DIR.
This includes:
- Pfam‑A HMM database
- SwissProt protein database
- GO ontology
- pfam2go mapping file
- Trinotate boilerplate SQLite database

Two additional resources — EggNOG v5 annotation table and Rfam covariance models —
had to be manually downloaded into the same directory, as they are not bundled with the Trinotate container:
```bash
cd "$DATA_DIR"

# EggNOG v5 annotation table
if [[ ! -s "e5.og_annotations.tsv.gz" ]]; then
    wget -O e5.og_annotations.tsv \
        "http://eggnog5.embl.de/download/eggnog_5.0/e5.og_annotations.tsv"
    gzip e5.og_annotations.tsv
fi
ln -sf e5.og_annotations.tsv.gz NOG.annotations.tsv.gz

# Rfam covariance models
if [[ ! -s "Rfam.cm" ]]; then
    wget -O Rfam.cm.gz \
        https://ftp.ebi.ac.uk/pub/databases/Rfam/CURRENT/Rfam.cm.gz
    gunzip Rfam.cm.gz
    cmpress Rfam.cm
fi
```
In addition, two small adjustments were required during the final Trinotate loading and report‑generation step to ensure that the EggNOG annotation file was accessible in the working directory and that the SQLite database was correctly initialised:
```bash
# Ensure EggNOG annotation file is visible in the Trinotate working directory
cd "$OUT_DIR"
ln -sf ../trinotate_data/e5.og_annotations.tsv.gz NOG.annotations.tsv.gz

# Seed the Trinotate database if the container fails to initialise it
if [[ ! -s "$OUT_DIR/Trinotate.sqlite" ]] || \
   ! sqlite3 "$OUT_DIR/Trinotate.sqlite" 'SELECT COUNT(*) FROM Transcript;' >/dev/null 2>&1; then
  rm -f "$OUT_DIR/Trinotate.sqlite"
  cp "$DATA_DIR/TrinotateBoilerplate.sqlite" "$OUT_DIR/Trinotate.sqlite"
  chmod 664 "$OUT_DIR/Trinotate.sqlite"
fi
```
