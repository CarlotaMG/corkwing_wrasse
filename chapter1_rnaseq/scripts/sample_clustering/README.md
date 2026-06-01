# Sample Clustering

This step explores global transcriptional variation across samples using Principal Component Analysis (PCA). Gene expression data were variance-stabilized and used to identify major axes of variation associated with temperature, population origin, and individual traits.

Correlations between PCA axes and morphometric variables (length, weight, and condition factor) were also assessed to evaluate the contribution of developmental stage to transcriptomic variation.

The analysis includes:

- Preparation and filtering of transcript abundance matrix  
- Variance-stabilizing transformation (VST) using DESeq2  
- Principal Component Analysis (PCA)  
- Correlation analysis between PCA axes and morphometric traits

---

## Inputs

- Transcript abundance matrix  
  `data/DE/abundance_matrix.txt`  

- Sample metadata  
  `data/sample_conditions_rnaseq.xlsx`  

---

## Outputs

Results are written to:

`results/sample_clustering/`

---

## Results

Full analysis report (code, plots, and summary tables):

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/sample_clustering.html



