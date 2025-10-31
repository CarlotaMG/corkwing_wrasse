# Chapter 1: Transcriptome assembly and temperature-dependent gene expression

This chapter focuses on transcriptome assembly and temperature-dependent gene expression in *Symphodus melops* from southern and western Norwegian populations and their hybrids, based on RNA-seq data. Individuals were experimentally exposed to three temperature treatments (12°C, 15°C, and 18°C) to assess transcriptional responses, local adaptation, and hybrid misregulation. 

Transcript extraction is organized into three tiers to capture different aspects of temperature response and divergence:

- **Tier 1**: Global temperature-responsive transcripts shared across origins, identified using the additive model.
- **Tier 2**: Local adaptation candidates identified by combining constitutive expression differences between origins (from the additive model) with origin-specific plasticity in response to temperature (from a likelihood ratio test comparing the interaction model to the additive model).
- **Tier 3**: Hybrid misregulation candidates identified from transcripts absent or misregulated in hybrids using the condition model.

This chapter includes:

- Guided de novo transcriptome assembly using Trinity
- Transcript annotation using Trinotate and genome-based GFF integration
- PCA and clustering to visualize sample structure
- Model comparison to evaluate differential expression patterns and select models for transcript extraction across tiers
- Differential expression analyses across temperature treatments and pedigrees using DESeq2
- Tiered transcript selection to identify temperature-responsive, locally adapted, and misexpressed candidate genes
- Functional enrichment of tiered transcript sets to identify associated biological processes and pathways

⸺

### Working Directory
All paths in this chapter assume `chapter1_rnaseq/` as the working directory. Scripts are designed to be run from this location using relative paths to ensure reproducibility across systems.

⸺

### Job Execution and SLURM Usage
Most scripts in this repository are modular and designed to run locally or on any Unix-based system. However, several computationally intensive steps — such as read trimming, transcriptome assembly and quantification — are designed to run on high-performance computing (HPC) systems using SLURM, and may not be executable outside such environments without modification.

> SLURM job scripts used during analysis are not included in the repository to maintain clarity. Instead, modular scripts are documented with usage examples and can be integrated into SLURM workflows as needed.

This design reflects the actual workflow used during analysis and supports reproducibility across HPC systems.

⸺

### Working Environment
This analysis was conducted in a mixed computational environment combining HPC modules, containerized tools, and R-based analyses.
Transcriptome assembly and annotation steps were performed each within their own Singularity container to ensure reproducibility and consistent software environments.

#### HPC Modules
The following environment modules were loaded on the Saga cluster during analysis:
- FastQC/0.12.1-Java-11
- MultiQC/1.22.3-foss-2023b
- Trimmomatic/0.39-Java-11
- STAR/2.7.10b-GCC-11.3.0
- SAMtools/1.16.1-GCC-11.3.0
- BUSCO/5.5.0-foss-2022b

#### Singularity Container for Trinity 
The container used during transcriptome assembly was pulled from Docker Hub on October 9, 2024. It included Trinity v2.15.2, along with other tools required for quantification and transcriptome processing.

The container was pulled from Docker Hub using:
```bash
singularity pull --dir resources/ docker://trinityrnaseq/trinityrnaseq
```

Scripts using Trinity are designed to run inside the container using:
```bash
singularity exec --bind $(pwd):$(pwd) resources/trinityrnaseq_latest.sif <command>
```

For more information, see [Trinity GitHub repository](https://github.com/trinityrnaseq/trinityrnaseq/tree/master/Docker).

#### Singularity Container for Trinotate
The container used during transcript annotation was downloaded from the Trinotate GitHub release page on October 25, 2025. It included Trinotate v4.0.2, along with supporting tools for transcript annotation and database integration.

The container was downloaded from the Broad Institute's Trinity resource server using:
```bash
singularity pull --dir resources/ \
https://data.broadinstitute.org/Trinity/TRINOTATE_SINGULARITY/trinotate.v4.0.2.simg
```

Scripts using Trinotate are designed to run inside the container using:
```bash
singularity exec --bind $(pwd):$(pwd) resources/trinotate.v4.0.2.simg <command>
```

For more information, see [Trinotate GitHub repository](https://github.com/Trinotate/Trinotate).

---

## Scripts

### Transcriptome assembly
#### Preprocessing and quality control:

[fastQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/fastQC.sh)

Runs FastQC on FASTQ files to assess read quality. This script is parameterized to work with both raw and trimmed reads by specifying input and output directories. An optional third argument allows you to set the number of threads (default: 4).

##### Inputs
- FASTQ files(*.fastq or *.fastq.gz) 
##### Outputs
- FastQC reports (*.html, *.zip)
##### Usage
```bash
bash scripts/assembly/preprocessing/fastaQC.sh <input_dir> <output_dir> [threads]
```
##### Examples
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

##### Inputs
- Directory containing FastQC output files (*.zip, *.html)
##### Outputs
- MultiQC summary report (multiqc_report.html) and associated files
##### Usage
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

##### Inputs
- Paired-end FASTQ files (*_R1.fastq.gz, *_R2.fastq.gz)
- Adapter file (e.g., TruSeq3-PE.fa)
##### Outputs
- *_R1_paired.fastq.gz
- *_R1_unpaired.fastq.gz
- *_R2_paired.fastq.gz
- *_R2_unpaired.fastq.gz
##### Usage
```bash
bash scripts/assembly/preprocessing/trimming.sh \
<file_R1> \
<file_R2> \
<output_dir> \
<adapter_file> \
<threads>
```
##### Slurm array job example
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

⸺

#### Mapping:
Before running guided de novo Trinity assembly, RNA-seq reads are aligned to the reference genome to produce coordinate-sorted BAM files. Trinity uses these alignments to partition reads into genomic loci, which are then assembled independently using de novo methods. This approach improves transcript reconstruction by incorporating genomic context while maintaining the flexibility of de novo assembly, including the potential to recover novel or unannotated transcripts.

[indexing.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/indexing.sh)

Builds a STAR genome index from the reference genome. This index is required for mapping reads with STAR.

##### Inputs
- Reference genome FASTA file
##### Outputs
- STAR genome index files
##### Usage
```bash
bash scripts/assembly/mapping/indexing.sh <genome_fasta> <output_dir>
```
##### Example
```bash
bash scripts/assembly/mapping/indexing.sh resources/ref_genome.fasta results/assembly/mapping/indexing
```
⸺

[mapping.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/mapping.sh)

Maps trimmed paired-end reads to the reference genome using STAR. This script loops through all samples in the input directory and produces sorted BAM files for each.

##### Inputs
- STAR genome index directory
- Trimmed paired-end FASTQ files (*_R1_paired.fastq.gz, *_R2_paired.fastq.gz)
##### Outputs
- Sorted BAM files for each sample
##### Usage
```bash
bash scripts/assembly/mapping/mapping.sh <index_dir> <trimmed_dir> <output_dir>
```
##### Example
```bash
bash scripts/assembly/mapping/mapping.sh \
results/assembly/mapping/indexing data/trimmed_fastq \
results/assembly/mapping
```
⸺

[concatBAM.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/concatBAM.sh)

Merges all individual BAM files from the mapping step into a single file for use in guided de novo Trinity assembly.

##### Inputs
- Directory containing sorted BAM files
##### Outputs
- Merged BAM file (combined_for_assembly.bam)
##### Usage
```bash
bash scripts/assembly/mapping/concatBAM.sh <bam_dir> <output_bam>
```
##### Example
```bash
bash scripts/assembly/mapping/concatBAM.sh \
results/assembly/mapping \
results/assembly/mapping/combined_for_assembly.bam
```
⸺

#### Run Trinity Assembly:

[trinity_run.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/trinity/trinity_run.sh)

Runs genome-guided de novo transcriptome assembly inside a Singularity container. The script takes a coordinate-sorted BAM file, a Singularity image, and an output directory as input.

##### Inputs
- Coordinate-sorted BAM file (combined_for_assembly.bam)
- Singularity image (trinityrnaseq_latest.sif)
##### Outputs
- Assembled transcriptome (Trinity-GG.fasta) and associated files for quantification and annotation
##### Usage
```bash
bash scripts/assembly/trinity/trinity_run.sh <bam_file> <singularity_image> <output_dir>
```
##### Example
```bash
bash scripts/assembly/trinity/trinity_run.sh \
results/mapping/combined_for_assembly.bam \
resources/trinityrnaseq_latest.sif results/assembly/trinity
```
> **Note:** Trinity was run in genome-guided mode with --genome_guided_max_intron 20000.
The Butterfly stage (--bflyHeapSpaceMax 10G) uses 10 GB per thread, multiplied by 16 threads (--bflyCPU 16), totaling 160 GB — consistent with the overall memory setting (--max_memory 160G).
To accommodate this, the script was executed via a SLURM job with --cpus-per-task=16 and a slightly higher memory allocation (--mem=170G) to ensure stability and account for container-related overhead.

⸺

#### Post-assembly Evaluation:

[trinity_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/trinity_stats.sh)

Generates basic statistics for the Trinity-assembled transcriptome using `TrinityStats.pl` inside a Singularity container. The script accepts three arguments: the Trinity FASTA file, the Singularity image, and the output file path.

##### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- Singularity image (`trinityrnaseq_latest.sif`)
##### Outputs
- Trinity assembly statistics (`trinity_stats.txt`)
##### Usage
```bash
bash scripts/assembly/post_assembly/stats/trinity_stats.sh \
<trinity_fasta> \
<singularity_image> \
<output_file>
```
##### Example
```bash
bash scripts/assembly/post_assembly/stats/trinity_stats.sh \
results/assembly/trinity/Trinity-GG.fasta \
resources/trinityrnaseq_latest.sif \
results/assembly/post_assembly/stats/trinity_stats.txt
```
⸺

[busco_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/busco_stats.sh)

Assesses the completeness of the Trinity-assembled transcriptome using BUSCO. The script accepts three arguments: the input FASTA file, the name of a BUSCO lineage dataset, the output directory, and optionally the number of threads.

##### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- BUSCO lineage dataset (e.g., actinopterygii_odb10)
##### Outputs
- Completeness metrics based on conserved orthologs, along with associated logs and intermediate files
##### Usage
```bash
bash scripts/assembly/post_assembly/stats/busco_stats.sh \
<input_fasta> \
<lineage_dataset> \
<output_dir> \
[num_threads]
```
##### Example
```bash
bash scripts/assembly/post_assembly/stats/busco_stats.sh \
results/assembly/trinity/Trinity-GG.fasta \
actinopterygii_odb10 \
results/assembly/post_assembly/stats/busco \
5
```
> **Note:**BUSCO writes auxiliary files to the current working directory regardless of --out_path. This script changes into the output directory before execution to ensure all files are contained and the project root remains clean.

⸺

#### Post-assembly Quantification:

[estimate_abundance.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/quantification/estimate_abundance.sh)

Estimates transcript abundance for a single sample using RSEM via Trinity utilities inside a Singularity container.
The script takes six arguments: a left reads FASTQ file, a right reads FASTQ file, a Trinity-assembled transcriptome FASTA file, a Singularity image, an output directory, and a thread count. It is designed to be modular and is typically called within a SLURM array job to process multiple samples in parallel.

##### Inputs
- Left FASTQ file (`*_R1_paired.fastq.gz`)
- Right FASTQ file (`*_R2_paired.fastq.gz`)
- Trinity-assembled transcriptome FASTA file
##### Outputs
- RSEM output files in a sample-specific subdirectory
- Log files (`.out`, `.err`)
##### Usage
```bash
bash scripts/quantification/estimate_abundance.sh \
<left_reads> \
<right_reads> \
<transcriptome_fasta> \
<singularity_image> \
<output_dir> \
<thread_count>
```
##### SLURM array job example
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
##### Inputs
- RSEM directories (e.g., results/quantification/rsem/rsem_*)
- Gene-to-transcript mapping file (e.g., results/assembly/trinity/Trinity-GG.fasta.gene_trans_map)
##### Ouputs
- Gene- and isoform-level abundance matrices
##### Usage
```bash
bash scripts/quantification/compile_abundance.sh \
<rsem_dir> \
<gene_trans_map> \
<singularity_image> \
<output_dir>
```
##### Example
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
##### Inputs
- RSEM directories (e.g., results/quantification/rsem/rsem_*)
##### Ouputs
- Per-sample cumulative count files, and combined summary file (`cumul_counts_combined.txt`)
##### Usage
```bash
bash scripts/quantification/cumulative_counts.sh <rsem_dir> <singularity_image> <output_dir>
```
##### Example
```bash
bash scripts/quantification/cumulative_counts.sh \
results/quantification \
trinityrnaseq_latest.sif \
results/quantification/cumulative_counts
```

⸺









#### trinities_filter_by_gene_cov.sh

This script filters Trinity-assembled transcripts based on their overlap with gene annotations from a custom GFF3 file (`fSymMel2.gff.gz`) for *Symphodus melops*.
Details on how this annotation was generated are available in the [Methods section](link-to-manuspt).
The script extracts:

- `Gene_ID`
- `Coverage_%` (default: 90%, customizable)
- `GO_Terms`
- `Dbxref`
- `UniProt_ID`

##### Usage

bash trinities_filter_by_gene_cov.sh <input.bed> <output.tsv> [coverage_threshold]

#### DE_model_comparison.Rmd

We compared three models for DE analysis:

- **Condition model**: Overfitted; explains most variance but lacks interpretability
- **Additive model**: Best balance of variance explained, DE power, and interpretability
- **Interaction model**: Adds value for a small subset of transcripts

**Final choice**: Additive model for global DE analysis
**Follow-up**: 741 transcripts with significant interaction effects retained for targeted analysis

#### additive_DE.Rmd

Performs differential expression analysis using the additive model across temperature treatments and origins.
This includes pairwise comparisons of temperature treatments across all origins, and origin contrasts across all temperatures.
To improve the interpretability of log2 fold changes, shrinkage was applied using either the apeglm or normal method. A helper function automatically selects the appropriate method based on whether the comparison involves the reference level in the DESeq2 design.
This approach ensures compatibility with DESeq2’s coefficient structure and enables flexible contrast-based comparisons while maintaining statistical robustness.

#### condition_DE.Rmd

Identifies transcripts misregulated or absent in hybrids using the condition model.
This included pairwise comparisons of temperature treatments within origins, as well as origin differences at each temperature. To improve the interpretability of log2 fold changes, shrinkage was applied using the *normal* method, which supports custom contrasts. Although *ashr* and *apeglm* offer lower bias in shrinkage estimation, they are not compatible with contrast-based comparisons in DESeq2, which extract coefficients post hoc rather than refitting the model. Therefore, the *normal* shrinkage method was used to enable these custom comparisons.

Differential expression analyses were conducted using the updated local DESeq2 implementation (v1.48.2).
Low-count transcripts (fewer than 10 total counts across all samples) were filtered out prior to DESeq2 analysis to reduce noise and improve statistical power.

### Project Structure

corkwing_wrasse/
├── LICENSE                  # Project license
├── README.md               # Project overview and instructions
├── chapter1_rnaseq/        # Main analysis folder
│   ├── data/               # Input data files
│   │   ├── DE/             # DESeq2 input matrices and contrast definitions
│   │   └── intersected_gff_with_transcriptomebam.bed.gz  # BEDTools intersection output
│   ├── results/            # DESeq2 results and plots
│   │   ├── DE/             # Differential expression results
│   │   ├── functional_enrichment/  # Tiered enrichment results
│   │   └── sample_clustering/      # PCA and MDS plots
│   └── scripts/           # RMarkdown and shell scripts for analysis
├── docs/                  # Rendered HTML reports

#### Intersected Transcriptome and Annotation

The file intersected_gff_with_transcriptomebam.bed.gz was generated using the following command:
bedtools intersect -abam transcriptome.bam -b annotation.gff -wa -wb -bed | gzip > intersected_gff_with_transcriptomebam.bed.gz

##### Data Sources

The BAM file was generated by mapping Trinity-assembled transcripts to the reference genome. This step is not yet included in the repository but will be added in a future update.
The GFF annotation file was provided by a collaborator. The link to the pipeline used to generate it will be documented once available.

### RNA-seq Analysis reports 

Rendered HTML reports from Chapter 1 are available via:

https://carlotamg.github.io/corkwing_wrasse/

This page links to:

- **DE Model Comparison** - Compares condition, additive, and interaction models. *(Generated from `scripts/DE_model_comparison.Rmd`)*
- **Additive Model DE** - Performs differential expression analyses using the additive model. *(Generated from `scripts/additive_DE.Rmd`)*
