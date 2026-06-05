# Transcriptome–Genome Intersection

This module describes the integration of the Trinity transcriptome with the genome-based annotation through coordinate-based intersection.

The Trinity transcriptome was first aligned to the reference genome to obtain genomic coordinates for each transcript. These alignments were then intersected with genome annotation features (GFF) to quantify the extent to which annotated mRNA gene models are recapitulated by assembled transcripts.

---

## Workflow

### 1. Transcriptome Alignment to Genome

### 2. Intersection with Genome Annotation

### 3. Coverage-Based Summarisation

---

### 1. Transcriptome Alignment to Genome

[align_transcriptome.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/genome_based/align_transcriptome.sh)

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

---

## 2. Intersection with Genome Annotation

[transcriptome_annotation_intersect.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/genome_based/transcriptome_annotation_intersect.sh)

Intersects transcriptome alignments with genome annotation features using bedtools intersect.

Prior to intersection, sequence identifiers in the BAM file are simplified to match those used in the genome annotation (e.g. ENA|...|OX393525.1 → OX393525.1), ensuring compatibility between datasets.

#### Inputs
- Coordinate-sorted BAM file from transcriptome alignment
- Genome annotation file (GFF)

#### Outputs
- Intersected features in BED format (transcriptome_annotation_intersection.bed.gz)

#### Usage
```bash
bash scripts/annotation/genome_based/transcriptome_annotation_intersect.sh \
<alignment.sorted.bam> \
<annotation.gff> \
<output_dir>
```
#### Example
```bash
bash scripts/annotation/genome_based/transcriptome_annotation_intersect.sh \
results/annotation/genome_based/alignment/alignment.sorted.bam \
resources/genome_based_annotations/fSymMel2.gff.gz \
results/annotation/genome_based/intersection
```

---

### 3. Coverage-Based Summarisation

[summarise_annotation_coverage.sh](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/scripts/annotation/genome_based/summarise_annotation_coverage.sh

Summarises transcript–annotation overlaps by computing the proportion of each Trinity transcript covered by annotated mRNA features. For each transcript, the best matching annotation (highest coverage) is retained.

Annotation metadata (e.g. transcript ID, gene ID, GO terms, and database cross-references) are extracted from the GFF attributes and reported alongside coverage values.

#### Inputs
- Intersected BED file from transcriptome–annotation overlap

#### Outputs
- Tab-delimited summary file

#### Usage
```bash
bash scripts/annotation/genome_based/summarise_annotation_coverage.sh \
<input.bed> \
[output.tsv] \
[coverage_threshold]
```
#### Example
```bash
bash scripts/annotation/genome_based/summarise_annotation_coverage.sh \
results/annotation/genome_based/intersection/transcriptome_annotation_intersection.bed \
results/annotation/genome_based/summary/annotation_coverage.tsv \
0
```

---

## Execution environment

All steps in this workflow were executed using HPC modules available on the Saga (Sigma2) cluster, including minimap2 for transcriptome alignment, samtools for BAM processing, and bedtools for coordinate-based intersection.

A complete list of modules and versions used in Chapter 1 is provided in the [Chapter 1 README (HPC Modules section)](https://github.com/CarlotaMG/corkwing_wrasse/blob/main/chapter1_rnaseq/README.md#hpc-modules).
