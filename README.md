# corkwing_wrasse

This repository accompanies a PhD project focused on the genomics and transcriptomics of the corkwing wrasse (*Symphodus melops*).

## trinities_filter_by_gene_cov.sh

This script filters Trinity transcripts based on their overlap with gene annotations from Ole's GFF file. It extracts:

- `Gene_ID`
- `Coverage_%` (default: 90%, customizable)
- `GO_Terms`
- `Dbxref`
- `UniProt_ID`

### Usage

```bash
bash trinities_filter_by_gene_cov.sh <input.bed> <output.tsv> [coverage_threshold]

