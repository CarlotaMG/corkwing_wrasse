# corkwing_wrasse

This repository accompanies a PhD project focused on the genomics and transcriptomics of the corkwing wrasse (*Symphodus melops*), a temperate marine fish. 


## Chapter 1: Transcriptome assembly and temperature-dependent gene expression

This chapter focuses on the de novo transcriptome assembly and transcriptomic responses to temperature treatments in *Symphodus melops*. 

Transcript extraction is organized into three tiers to capture different aspects of temperature response and divergence:

- **Tier 1**: Global temperature-responsive transcripts shared across origins, identified using the additive model.
- **Tier 2**: Local adaptation candidates identified by combining constitutive expression differences between origins (from the additive model) with origin-specific plasticity in response to temperature (from a likelihood ratio test comparing the interaction model to the additive model).
- **Tier 3**: Hybrid misregulation candidates identified from transcripts absent or misregulated in hybrids using the condition model.

This chapter includes:

- Assembly of Trinity-assembled transcripts.
- Filtering and annotation of transcripts based on a custom genome annotation.
- PCA and clustering to visualize sample structure.
- Model comparison to evaluate differential expression patterns and select models for transcript extraction across tiers.
- Differential expression analyses across temperature treatments and pedigrees.
- Functional enrichment analysis to identify biological processes and pathways associated with temperature-responsive genes.

### Scripts

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

#### Data Sources

The BAM file was generated by mapping Trinity-assembled transcripts to the reference genome. This step is not yet included in the repository but will be added in a future update.
The GFF annotation file was provided by a collaborator. The link to the pipeline used to generate it will be documented once available.

