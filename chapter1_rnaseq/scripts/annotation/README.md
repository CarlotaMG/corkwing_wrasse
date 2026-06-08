# Annotation

This section describes the functional annotation workflow applied to the Trinity-assembled transcriptome. Multiple complementary approaches were used for functional annotation, combining transcript-level annotation (EggNOG-mapper, InterProScan, and Trinotate) with genome-based annotation integrated via transcriptome–genome intersection.
The workflow integrates these sources through comparison and merging to produce a unified annotation dataset for downstream analyses and consists of three main components:

1. Genome-based annotation  
2. Transcriptome-based annotation  
3. Annotation comparison and integration  

---
## 1. Genome-based Annotation

### Genome annotation

Genome-based annotation was generated as part of this project using a custom genome annotation pipeline integrating RNA-seq data from this study within an evidence-based framework (Evidence Modeler, EVM) for gene model prediction. This pipeline was conducted separately and is not included in this repository.

The resulting annotation includes gene models and corresponding predicted protein sequences, along with functional annotations such as InterPro, Pfam, PANTHER, Gene Ontology (GO), and UniProt identifiers.

The annotation was further processed by aligning the Trinity transcriptome to the reference genome, standardising FASTA headers for compatibility, and intersecting transcript alignments (BAM) with genome annotation features (GFF). The resulting overlaps were processed and summarised based on the coverage of annotated mRNA models by assembled transcripts, providing a quantitative measure of agreement between annotated gene models and transcript reconstructions.

Detailed processing steps and scripts are described in [Transcriptome–Genome Intersection](https://github.com/CarlotaMG/corkwing_wrasse/tree/main/chapter1_rnaseq/scripts/annotation/genome_based)

The genome-based annotations are available at:
https://doi.org/XXXXX

---

## 2. Transcriptome-based annotation

Functional annotation of the Trinity transcriptome was performed using three complementary pipelines:

- [Trinotate](https://github.com/CarlotaMG/corkwing_wrasse/tree/main/chapter1_rnaseq/scripts/annotation/trinotate)
- [EggNOG‑mapper](https://github.com/CarlotaMG/corkwing_wrasse/tree/main/chapter1_rnaseq/scripts/annotation/eggnog)
- [InterProScan](https://github.com/CarlotaMG/corkwing_wrasse/tree/main/chapter1_rnaseq/scripts/annotation/ips)

Each pipeline was executed independently and provides distinct sources of functional annotation (homology, protein domains, orthology, and structural features). The results from all pipelines are integrated downstream into a unified annotation framework.

---

## 3. Annotation Comparison and Integration

Annotation outputs from EggNOG, InterProScan (IPS), Trinotate, and genome-based annotation were compared and integrated into a unified gene-level annotation table for the Trinity transcriptome.

The following was performed:

- standardises gene and transcript identifiers across annotation sources  
- integrates SignalP and DeepTMHMM predictions into Trinotate outputs  
- extracts and harmonises functional annotations (GO, KEGG, domains)  
- combines complementary evidence into a unified annotation table  
- classifies genes based on annotation support  
- evaluates annotation coverage and overlap across sources  
- summarises annotation patterns across functional tiers  

### Inputs

- EggNOG annotation outputs  
- InterProScan (IPS) outputs  
- Trinotate report (including SignalP and DeepTMHMM integration)  
- Genome-based annotation  

### Outputs

- Integrated annotation table combining all sources  
- Annotation classification (e.g. well-annotated, partially annotated, unannotated)  
- Summary statistics of annotation coverage  
- Annotation overlap analyses across sources  
- Tier-specific annotation summaries  


### Results

Full analysis report (code, tables, plots, and interpretation):

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/annotations.html

### Environment

All required R packages and versions are documented within the analysis report.

