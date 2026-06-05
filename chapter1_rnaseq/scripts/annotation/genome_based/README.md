# Transcriptome–Genome Intersection

## Overview

This module describes the integration of the Trinity transcriptome with the genome-based annotation through coordinate-based intersection.

The Trinity transcriptome was first aligned to the reference genome to obtain genomic coordinates for each transcript. These alignments were then intersected with genome annotation features (GFF) to quantify the extent to which annotated mRNA gene models are recapitulated by assembled transcripts.

---

## Workflow

### 1. Transcriptome Alignment to Genome

### 2. Header Standardisation

### 3. Intersection with Genome Annotation

### 4. Coverage-Based Summarisation

---

# Transcriptome–Genome Intersection

## Overview
# Transcriptome–Genome Intersection
This module describes the integration of the Trinity transcriptome with the genome-based annotation through coordinate-based intersection.

The Trinity transcriptome was first aligned to the reference genome to obtain genomic coordinates for each transcript. These alignments were then intersected with genome annotation features (GFF) to quantify the extent to which annotated mRNA gene models are recapitulated by assembled transcripts.

---

## Workflow

### 1. Transcriptome Alignment to Genome

./align_transcriptome.sh

Aligns the assembled transcriptome to the reference genome using minimap2 in splice-aware mode. The resulting alignments are converted to BAM format, sorted, and indexed using samtools.

This step assigns genomic coordinates to assembled transcripts, enabling downstream comparison with genome annotation features.

#### Inputs
- Transcriptome FASTA file (e.g. Trinity assembly)
- Reference genome FASTA file

#### Outputs
- SAM alignment file (`alignment.sam`)
- BAM alignment file (`alignment.bam`)
- Coordinate-sorted BAM file (`alignment.sorted.bam`)
- BAM index file (`alignment.sorted.bam.bai`)

#### Usage
```bash
bash scripts/annotation/genome_based/align_transcriptome.sh \
<transcriptome.fasta> \
<reference_genome.fasta> \
<output_dir> \
[threads]
```
#### Example
```bash
bash scripts/annotation/genome_based/align_transcriptome.sh \
results/assembly/trinity/Trinity-GG.fasta \
resources/genome/fSymMel2.fa \
results/annotation/genome_based/alignment \
8
```
> **Note:** Minimap2 is run in splice-aware mode (-ax splice) to account for exon–intron structure in transcript alignments. The number of threads can be adjusted via the optional argument and should typically match the number of CPUs allocated in an HPC job (e.g. $SLURM_CPUS_PER_TASK).
