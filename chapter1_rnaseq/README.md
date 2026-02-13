# Chapter 1: Transcriptome assembly and temperature-dependent gene expression

This chapter focuses on transcriptome assembly and temperature-dependent gene expression in *Symphodus melops* from southern and western Norwegian populations and their hybrids, based on RNA-seq data. Individuals were experimentally exposed to three temperature treatments (12°C, 15°C, and 18°C) to assess transcriptional responses, local adaptation, and hybrid misregulation. 

Transcript extraction is organized into three tiers to capture different aspects of temperature response and divergence:

- **Tier 1**: Global temperature-responsive transcripts shared across origins, identified using the additive model.
- **Tier 2**: Local adaptation candidates identified by combining constitutive expression differences between origins (from the additive model) with origin-specific plasticity in response to temperature (from a likelihood ratio test comparing the interaction model to the additive model).
- **Tier 3**: Hybrid misregulation candidates identified from transcripts absent or misregulated in hybrids using the condition model.

This chapter includes:

- Guided de novo transcriptome assembly using Trinity
- Transcript annotation with Trinotate, EggNog, InterProScan and Genome-Based GFF Integration
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
The following environment modules were loaded on Saga (Sigma2 cluster) during analysis:
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

#### EggNOG‑mapper environment
eggNOG‑mapper is run inside an Apptainer container and requires the full eggNOG v5.0.2 database.

Container:
- `quay.io/biocontainers/eggnog-mapper:2.1.13--pyhdfd78af_2`
  (pulled as a `.sif` file by `eggnog_prepare.sh`)

Database:
- eggNOG v5.0.2 (downloaded and unpacked by `eggnog_prepare.sh`; includes DIAMOND, MMseqs2, PFAM, and taxonomy databases)

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

### Transcriptome Annotation (Trinotate Pipeline)

The Trinotate pipeline integrates multiple evidence sources for functional annotation, including ORF prediction, homology searches, protein domains, signal peptides, and transmembrane regions. All results are loaded into a unified SQLite database for downstream queries and reporting.

#### Execution Overview

The annotation workflow combines Singularity containers, HPC modules, and external tools that require custom installation. Each component was executed in the environment best suited for performance and reproducibility:

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

⸺

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
⸺

[pfam.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/pfam.sh)

Runs hmmscan on predicted peptide sequences to identify conserved protein domains, The script takes a peptide FASTA file, a Singularity image, a desired filename for the Pfam-A HMM file, an output directory, and the number of threads to use. If the HMM file is missing, it is downloaded and decompressed. The script then builds the HMM database using hmmpress and scans the peptide sequences with hmmscan.
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
cat /results/annotation/trinotate/pfam/chunks/*/*.domtblout > /results/annotation/trinotate/pfam/pfam_merged.domtblout
```

⸺

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

⸺

#### BLASTX

BLASTX was used to search the Trinity transcriptome against the SwissProt protein database using the BLAST+ module available on the Saga cluster. Because the dataset was large, the transcriptome FASTA was processed in chunks using SLURM array jobs. Per‑chunk BLASTX outputs were then merged into a single file for Trinotate

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

⸺

### SignalP
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

[signalp_chunking.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/trinotate/tmhmm_chunking.sh)

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
- Merged SignalP region annotations (signalp_merged.region_output.gff3)
#### Usage
```bash
bash signalp_merge.sh <chunks_dir> <merged_dir>
```
#### Example
```bash
bash scripts/annotation/trinotate/signalp_merge.sh \
    results/annotation/trinotate/signalp/chunks \
    results/annotation/trinotate/signalp/merged
```

⸺

### DeepTMHMM
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

⸺

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
⸺

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

⸺

### Transcriptome Annotation (eggNOG‑mapper Pipeline)
EggNOG‑mapper was used to assign orthology‑based functional annotations to predicted proteins.
The workflow consists of three scripts: one for preparing the container and database, one for running the annotation, and one for extracting GO/KO/KEGG/COG terms from the .emapper.annotations file.
All steps were executed on the Saga cluster using Apptainer and node‑local scratch for performance.

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

⸺

### Transcriptome Annotation (InterProScan)

InterProScan was used to annotate predicted proteins with domain signatures, GO terms, and InterPro accessions.
IPS was run using the InterProScan module available on the Saga cluster.
Because the dataset was large, the peptide FASTA was processed in chunks using SLURM array jobs.
Per‑chunk IPS outputs were then merged into a single file for downstream Trinotate integration.

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
