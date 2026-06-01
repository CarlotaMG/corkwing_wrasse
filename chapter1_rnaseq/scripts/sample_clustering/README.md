# Sample Clustering

This step explores global transcriptional variation across samples using Principal Component Analysis (PCA). Gene expression data were variance-stabilized and used to identify major axes of variation associated with temperature, population origin, and individual traits.

This analysis is implemented in R and includes preparation and filtering of the transcript abundance matrix, variance-stabilizing transformation (VST) using DESeq2, PCA, and correlation analyses between PCA axes and morphometric variables (length, weight, and condition factor) to evaluate the contribution of developmental stage to transcriptomic variation.

---

## Inputs

- Transcript abundance matrix  
- Sample metadata  

---

## Outputs

Key outputs include:

- PCA plots  
- Variance explained summaries  
- PCA score tables  
- Correlation analyses and scatterplots  

---

## Results

Full analysis report (code, plots, and summary tables):

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/DE_reports/PCA.html
