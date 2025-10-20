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
Most scripts in this repository are modular and designed to run locally or on any Unix-based system. However, several computationally intensive steps — such as read trimming, transcriptome assembly, annotation, and quantification — are designed to run on high-performance computing (HPC) systems using SLURM, and may not be executable outside such environments without modification.

> SLURM job scripts used during analysis are not included in the repository to maintain clarity. Instead, modular scripts are documented with usage examples and can be integrated into SLURM workflows as needed.

This design reflects the actual workflow used during analysis and supports reproducibility across HPC systems.

⸺

### Singularity Container for Trinity 
To ensure reproducibility and consistent software environments, all steps related to transcriptome assembly were performed within a Singularity container.

This includes:
- **Trinity v2.15.2** for guided de novo transcriptome assembly


> **Note:** Downstream analyses (differential expression, clustering, genome-based GFF integration, functional enrichment) was performed outside the container in R environments. Trinotate-based annotation was performed using a separate container.

The container was pulled from Docker Hub using:

singularity pull docker://trinityrnaseq/trinityrnaseq


Scripts using Trinity are designed to run inside the container using:

singularity exec --bind $(pwd):$(pwd) trinityrnaseq_latest.sif <command>


For more information, see [Trinity GitHub repository](https://github.com/trinityrnaseq/trinityrnaseq/tree/master/Docker).

---

## Scripts

### Transcriptome assembly
#### Preprocessing and quality control:

[fastQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/fastaQC.sh)

Runs FastQC on FASTQ files to assess read quality. This script is parameterized to work with both raw and trimmed reads by specifying input and output directories.

##### Inputs
- FASTQ files(*.fastq or *.fastq.gz) 
##### Outputs
- FastQC reports (*.html, *.zip)
##### Usage
bash scripts/assembly/preprocessing/fastaQC.sh <input_dir> <output_dir>
##### Examples
bash scripts/assembly/preprocessing/fastaQC.sh data/raw_fastq results/assembly/preprocessing/fastaQC/raw

bash scripts/assembly/preprocessing/fastaQC.sh data/trimmed_fastq results/assembly/preprocessing/fastaQC/trimmed

⸺

[multiQC.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/multiQC.sh)

Aggregates FastQC reports into a single summary using MultiQC. This script is designed to work with any directory containing FastQC output files.

##### Inputs
- Directory containing FastQC output files (*.zip, *.html)
##### Outputs
- MultiQC summary report (multiqc_report.html) and associated files
##### Usage
bash scripts/assembly/preprocessing/multiQC.sh <input_dir> <output_dir>
#### Examples
bash scripts/assembly/preprocessing/multiQC.sh results/assembly/preprocessing/fastaQC/raw results/assembly/preprocessing/multiQC/raw

bash scripts/assembly/preprocessing/multiQC.sh results/assembly/preprocessing/fastaQC/trimmed results/assembly/preprocessing/multiQC/trimmed

⸺

[trimming.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/preprocessing/trimming.sh)

Runs Trimmomatic in paired-end mode to trim RNA-seq reads. This script is designed to be executed as part of a SLURM array job and accepts three arguments: input directory, output directory, and adapter file.

##### Inputs
- Paired-end FASTQ files (*_R1.fastq.gz, *_R2.fastq.gz)
- Adapter file (TruSeq3-PE.fa)
##### Outputs
- *_R1_paired.fastq.gz
- *_R1_unpaired.fastq.gz
- *_R2_paired.fastq.gz
- *_R2_unpaired.fastq.gz
##### Usage
sbatch --array=0-`<N>` scripts/assembly/preprocessing/trimming.sh <input_dir> <output_dir> <adapter_file>
> Where `<N>` is the number of input FASTQ files minus one. For example, if you have 39 paired-end samples (78 FASTQ files total), use --array=0-77.
##### Example
sbatch --array=0-77 scripts/assembly/preprocessing/trimming.sh data/raw_fastq data/trimmed_fastq resources/TruSeq3-PE.fa

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
bash scripts/assembly/mapping/indexing.sh <genome_fasta> <output_dir>
##### Example
bash scripts/assembly/mapping/indexing.sh resources/ref_genome.fasta results/assembly/mapping/indexing

⸺

[mapping.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/mapping.sh)

Maps trimmed paired-end reads to the reference genome using STAR. This script loops through all samples in the input directory and produces sorted BAM files for each.

##### Inputs
- STAR genome index directory
- Trimmed paired-end FASTQ files (*_R1_paired.fastq.gz, *_R2_paired.fastq.gz)
##### Outputs
- Sorted BAM files for each sample
##### Usage
bash scripts/assembly/mapping/mapping.sh <index_dir> <trimmed_dir> <output_dir>
##### Example
bash scripts/assembly/mapping/mapping.sh  results/assembly/mapping/indexing data/trimmed_fastq results/assembly/mapping

⸺

[concatBAM.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/mapping/concatBAM.sh)

Merges all individual BAM files from the mapping step into a single file for use in guided de novo Trinity assembly.

##### Inputs
- Directory containing sorted BAM files
##### Outputs
- Merged BAM file (combined_for_assembly.bam)
##### Usage
bash scripts/assembly/mapping/concatBAM.sh <bam_dir> <output_bam>
##### Example
bash scripts/assembly/mapping/concatBAM.sh results/assembly/mapping results/assembly/mapping/combined_for_assembly.bam

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
bash scripts/assembly/trinity/trinity_run.sh <bam_file> <singularity_image> <output_dir>
##### Example
bash scripts/assembly/trinity/trinity_run.sh results/mapping/combined_for_assembly.bam resources/trinityrnaseq_latest.sif results/assembly/trinity

> **Note:** Trinity was run in genome-guided mode with --genome_guided_max_intron 20000.
The Butterfly stage (--bflyHeapSpaceMax 10G) uses 10 GB per thread, multiplied by 16 threads (--bflyCPU 16), totaling 160 GB — consistent with the overall memory setting (--max_memory 160G).
To accommodate this, the script was executed via a SLURM job with --cpus-per-task=16 and a slightly higher memory allocation (--mem=170G) to ensure stability and account for container-related overhead.

⸺

#### Post-assembly evaluation:

[trinity_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/trinity_stats.sh)

Generates basic statistics for the Trinity-assembled transcriptome using `TrinityStats.pl` inside a Singularity container. The script accepts three arguments: the Trinity FASTA file, the Singularity image, and the output file path.

##### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- Singularity image (`trinityrnaseq_latest.sif`)
##### Outputs
- Trinity assembly statistics (`trinity_stats.txt`)
##### Usage
bash scripts/assembly/post_assembly/stats/trinity_stats.sh <trinity_fasta> <singularity_image> <output_file>
##### Example
bash scripts/assembly/post_assembly/stats/trinity_stats.sh results/assembly/trinity/Trinity-GG.fasta resources/trinityrnaseq_latest.sif results/assembly/post_assembly/stats/trinity_stats.txt

⸺

[busco_stats.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/assembly/post_assembly/stats/busco_stats.sh)

Assesses the completeness of the Trinity-assembled transcriptome using BUSCO v5.5.0. The script accepts three arguments: the input FASTA file, the name of a BUSCO lineage dataset, and the output directory.

##### Inputs
- Trinity-assembled transcriptome (Trinity-GG.fasta)
- BUSCO lineage dataset (e.g., actinopterygii_odb10)
- Output directory (e.g., results/assembly/post_assembly/stats/busco/)
##### Outputs
- Completeness metrics based on conserved orthologs, along with associated logs and intermediate files
##### Usage
bash scripts/assembly/post_assembly/stats/busco_stats.sh <input_fasta> <lineage_dataset> <output_dir>
##### Example
bash scripts/assembly/post_assembly/stats/busco_stats.sh results/assembly/trinity/Trinity-GG.fasta actinopterygii_odb10 results/assembly/post_assembly/stats/busco

> **Note:**BUSCO writes auxiliary files to the current working directory regardless of --out_path. This script changes into the output directory before execution to ensure all files are contained and the project root remains clean.
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
