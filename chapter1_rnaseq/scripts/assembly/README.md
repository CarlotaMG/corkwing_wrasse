# Transcriptome Assembly

## Overview

Transcriptome assembly was performed using a genome-guided de novo approach with Trinity. RNA-seq reads were quality controlled, trimmed, and aligned to the reference genome using STAR. Alignments were used to guide transcriptome assembly, followed by evaluation and transcript quantification.

---

## Pipeline Structure

The assembly workflow consists of five stages:

1. Preprocessing and Quality Control 
2. Read Mapping (genome-guided setup) 
3. Transcriptome Assembly 
4. Post-assembly Evaluation 
5. Transcript Quantification 

---

## Directory Structure

The assembly workflow is organized into modular components:

```
scripts/assembly/
├── preprocessing/        # Quality control and trimming
├── mapping/              # Genome-guided alignment
├── trinity/              # Transcriptome assembly
└── post_assembly/
    ├── stats/            # Assembly evaluation (BUSCO, stats)
    └── quantification/   # Transcript abundance estimation
```

Most output directories are created automatically by scripts; however, some base directories are expected to exist. Script usage examples below illustrate the expected input and output paths.

---

## 1. Preprocessing and quality control

[fastQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/fastQC.sh)

Runs FastQC on FASTQ files to assess read quality. This script is parameterized to work with both raw and trimmed reads by specifying input and output directories. An optional third argument allows you to set the number of threads (default: 4).

#### Inputs
- FASTQ files(*.fastq or *.fastq.gz)
#### Outputs
- FastQC reports (*.html, *.zip)
#### Usage
```bash
bash scripts/assembly/preprocessing/fastaQC.sh <input_dir> <output_dir> [threads]
```
#### Examples
```bash
bash scripts/assembly/preprocessing/fastaQC.sh \
data/raw_fastq \
results/assembly/preprocessing/fastaQC/raw \
5
```
```bash
bash scripts/assembly/preprocessing/fastaQC.sh \
data/trimmed_fastq \
results/assembly/preprocessing/fastaQC/trimmed \
5
```

⸺

[multiQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/multiQC.sh)

Aggregates FastQC reports into a single summary using MultiQC. This script is designed to work with any directory containing FastQC output files.

#### Inputs
- Directory containing FastQC output files (*.zip, *.html)
#### Outputs
- MultiQC summary report (multiqc_report.html) and associated files
#### Usage
```bash
bash scripts/assembly/preprocessing/multiQC.sh <input_dir> <output_dir>
```
#### Examples
```bash
bash scripts/assembly/preprocessing/multiQC.sh \
results/assembly/preprocessing/fastaQC/raw \
results/assembly/preprocessing/multiQC/raw
```
```bash
bash scripts/assembly/preprocessing/multiQC.sh \
results/assembly/preprocessing/fastaQC/trimmed \
results/assembly/preprocessing/multiQC/trimmed
```

⸺

[trimming.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/trimming.sh)

Trims paired-end RNA-seq reads using Trimmomatic.
This script takes five arguments: a forward reads FASTQ file, a reverse reads FASTQ file, an adapter file, an output directory, and a thread count. It is designed to be modular and is typically called within a SLURM array job to process multiple samples in parallel.

#### Inputs
- Paired-end FASTQ files (*_R1.fastq.gz, *_R2.fastq.gz)
- Adapter file (e.g., TruSeq3-PE.fa)
#### Outputs
- *_R1_paired.fastq.gz
- *_R1_unpaired.fastq.gz
- *_R2_paired.fastq.gz
- *_R2_unpaired.fastq.gz
#### Usage
```bash
bash scripts/assembly/preprocessing/trimming.sh \
<file_R1> \
<file_R2> \
<output_dir> \
<adapter_file> \
<threads>
```[multiQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/mult>

Aggregates FastQC reports into a single summary using MultiQC. This script is designed to work with any directory conta>

#### Inputs
- Directory containing FastQC output files (*.zip, *.html)
#### Outputs
- MultiQC summary report (multiqc_report.html) and associated files
#### Usage
```bash
bash scripts/assembly/preprocessing/multiQC.sh <input_dir> <output_dir>
```
#### Examples
```bash
bash scripts/assembly/preprocessing/multiQC.sh \
results/assembly/preprocessing/fastaQC/raw \
results/assembly/preprocessing/multiQC/raw
```
```bash
bash scripts/assembly/preprocessing/multiQC.sh \
results/assembly/preprocessing/fastaQC/trimmed \
results/assembly/preprocessing/multiQC/trimmed
```
#### Slurm array job example
```bash
R1_FILES=(data/raw_fastq/*_R1.fastq.gz)
FILE_R1=${R1_FILES[$SLURM_ARRAY_TASK_ID]}
FILE_R2=${FILE_R1/_R1.fastq.gz/_R2.fastq.gz}

bash scripts/assembly/preprocessing/trimming.sh \
"$FILE_R1" \
"$FILE_R2" \
data/trimmed_fastq \
resources/adapters/TruSeq3-PE.fa \
$SLURM_CPUS_PER_TASK
```

---

## 2. Mapping
Before running guided de novo Trinity assembly, RNA-seq reads are aligned to the reference genome to produce coordinate-sorted BAM files. Trinity uses these alignments to partition reads into genomic loci, which are then assembled independently using de novo methods. This approach improves transcript reconstruction by incorporating genomic context while maintaining the flexibility of de novo assembly, including the potential to recover novel or unannotated transcripts.

[indexing.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/indexing.sh)

Builds a STAR genome index from the reference genome. This index is required for mapping reads with STAR.

#### Inputs
- Reference genome FASTA file
#### Outputs
- STAR genome index files
#### Usage
```bash
bash scripts/assembly/mapping/indexing.sh <genome_fasta> <output_dir>
```
#### Example
```bash
bash scripts/assembly/mapping/indexing.sh resources/ref_genome.fasta results/assembly/mapping/indexing
```
⸺

[mapping.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/mapping.sh)

Maps trimmed paired-end reads to the reference genome using STAR. This script loops through all samples in the input directory and produces sorted BAM files for each.

#### Inputs
- STAR genome index directory
- Trimmed paired-end FASTQ files (*_R1_paired.fastq.gz, *_R2_paired.fastq.gz)
#### Outputs
- Sorted BAM files for each sample
#### Usage
```bash
bash scripts/assembly/mapping/mapping.sh <index_dir> <trimmed_dir> <output_dir>
```
#### Example
```bash
bash scripts/assembly/mapping/mapping.sh \
results/assembly/mapping/indexing data/trimmed_fastq \
results/assembly/mapping
```
⸺

[concatBAM.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/concatBAM.sh)

Merges all individual BAM files from the mapping step into a single file for use in guided de novo Trinity assembly.

#### Inputs
- Directory containing sorted BAM files
#### Outputs
- Merged BAM file (combined_for_assembly.bam)
#### Usage
```bash
bash scripts/assembly/mapping/concatBAM.sh <bam_dir> <output_bam>
```
#### Example
```bash
bash scripts/assembly/mapping/concatBAM.sh \
results/assembly/mapping \
results/assembly/mapping/combined_for_assembly.bam
```

---

### 3. Run Trinity Assembly

[trinity_run.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/trinity/trinity_run.sh)

Runs genome-guided de novo transcriptome assembly inside a Singularity container. The script takes a coordinate-sorted BAM file, a Singularity image, and an output directory as input.

#### Inputs
- Coordinate-sorted BAM file (combined_for_assembly.bam)
- Singularity image (trinityrnaseq_latest.sif)
#### Outputs
- Assembled transcriptome (Trinity-GG.fasta) and associated files for quantification and annotation
#### Usage
```bash
bash scripts/assembly/trinity/trinity_run.sh <bam_file> <singularity_image> <output_dir>
```
#### Example
```bash
bash scripts/assembly/trinity/trinity_run.sh \
results/mapping/combined_for_assembly.bam \
resources/trinityrnaseq_latest.sif results/assembly/trinity
```
> **Note:** Trinity was run in genome-guided mode with --genome_guided_max_intron 20000.
The Butterfly stage (--bflyHeapSpaceMax 10G) uses 10 GB per thread, multiplied by 16 threads (--bflyCPU 16), totaling 160 GB — consistent with the overall memory setting (--max_memory 160G).
To accommodate this, the script was executed via a SLURM job with --cpus-per-task=16 and a slightly higher memory allocation (--mem=170G) to ensure stability and account for container-related overhead.

---

## 4. Post-assembly Evaluation:

[trinity_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/trinity_stats.sh)

Generates basic statistics for the Trinity-assembled transcriptome using `TrinityStats.pl` inside a Singularity container. The script accepts three arguments: the Trinity FASTA file, the Singularity image, and the output file path.

#### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- Singularity image (`trinityrnaseq_latest.sif`)
#### Outputs
- Trinity assembly statistics (`trinity_stats.txt`)
#### Usage
```bash
bash scripts/assembly/post_assembly/stats/trinity_stats.sh \
<trinity_fasta> \
<singularity_image> \
<output_file>
```
#### Example
```bash
bash scripts/assembly/post_assembly/stats/trinity_stats.sh \
results/assembly/trinity/Trinity-GG.fasta \
resources/trinityrnaseq_latest.sif \
results/assembly/post_assembly/stats/trinity_stats.txt
```
⸺

[busco_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/busco_stats.sh)

Assesses the completeness of the Trinity-assembled transcriptome using BUSCO. The script accepts three arguments: the input FASTA file, the name of a BUSCO lineage dataset, the output directory, and optionally the number of threads.

#### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- BUSCO lineage dataset (e.g., actinopterygii_odb10)
#### Outputs
- Completeness metrics based on conserved orthologs, along with associated logs and intermediate files
#### Usage
```bash
bash scripts/assembly/post_assembly/stats/busco_stats.sh \
<input_fasta> \
<lineage_dataset> \
<output_dir> \
[num_threads]
```
#### Example
```bash
bash scripts/assembly/post_assembly/stats/busco_stats.sh \
results/assembly/trinity/Trinity-GG.fasta \
actinopterygii_odb10 \
results/assembly/post_assembly/stats/busco \
5
```
> **Note:**BUSCO writes auxiliary files to the current working directory regardless of --out_path. This script changes into the output directory before execution to ensure all files are contained and the project root remains clean.

---

## 5. Post-assembly Quantification:

[estimate_abundance.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/quantification/estimate_abundance.sh)

Estimates transcript abundance for a single sample using RSEM via Trinity utilities inside a Singularity container.
The script takes six arguments: a left reads FASTQ file, a right reads FASTQ file, a Trinity-assembled transcriptome FASTA file, a Singularity image, an output directory, and a thread count. It is designed to be modular and is typically called within a SLURM array job to process multiple samples in parallel.

#### Inputs
- Left FASTQ file (`*_R1_paired.fastq.gz`)
- Right FASTQ file (`*_R2_paired.fastq.gz`)
- Trinity-assembled transcriptome FASTA file
#### Outputs
- RSEM output files in a sample-specific subdirectory
- Log files (`.out`, `.err`)
#### Usage
```bash
bash scripts/quantification/estimate_abundance.sh \
<left_reads> \
<right_reads> \
<transcriptome_fasta> \
<singularity_image> \
<output_dir> \
<thread_count>
```
#### SLURM array job example
```bash
R1_FILES=(data/trimmed_fastq/*_R1_paired.fastq.gz)
R1_FILE=${R1_FILES[$SLURM_ARRAY_TASK_ID]}
R2_FILE=${R1_FILE/_R1_paired.fastq.gz/_R2_paired.fastq.gz}

bash scripts/quantification/estimate_abundance.sh \
"$R1_FILE" \
"$R2_FILE" \
results/assembly/trinity/Trinity-GG.fasta \
resources/containers/trinityrnaseq_latest.sif \
results/quantification/rsem \
$SLURM_CPUS_PER_TASK
```

⸺

[compile_abundance.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/quantification/compile_abundance.sh)

Compiles gene- and isoform-level abundance matrices from RSEM output files.
The script takes four arguments: a directory containing RSEM output files, a gene-to-transcript mapping file, a Singularity image, and an output directory.
#### Inputs
- RSEM directories (e.g., results/quantification/rsem/rsem_*)
- Gene-to-transcript mapping file (e.g., results/assembly/trinity/Trinity-GG.fasta.gene_trans_map)
#### Ouputs
- Gene- and isoform-level abundance matrices
#### Usage
```bash
bash scripts/quantification/compile_abundance.sh \
<rsem_dir> \
<gene_trans_map> \
<singularity_image> \
<output_dir>
```
#### Example
```bash
bash scripts/quantification/compile_abundance.sh results/quantification/rsem \
results/assembly/trinity/Trinity-GG.fasta.gene_trans_map \
resources/containers/trinityrnaseq_latest.sif \
results/quantification/compiled
```
⸺

[cumulative_counts.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/quantification/cumulative_counts.sh)

Computes cumulative feature counts across samples.
The script takes three arguments: a directory containing RSEM output files, a Singularity image, and an output directory.
#### Inputs
- RSEM directories (e.g., results/quantification/rsem/rsem_*)
#### Ouputs
- Per-sample cumulative count files, and combined summary file (`cumul_counts_combined.txt`)
#### Usage
```bash
bash scripts/quantification/cumulative_counts.sh <rsem_dir> <singularity_image> <output_dir>
```
#### Example
```bash
bash scripts/quantification/cumulative_counts.sh \
results/quantification \
trinityrnaseq_latest.sif \
results/quantification/cumulative_counts
```
