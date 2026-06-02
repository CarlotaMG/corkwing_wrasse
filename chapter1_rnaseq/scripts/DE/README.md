# Differential Expression

This step identifies gene expression patterns associated with temperature, population, and hybrid inheritance in *Symphodus melops*.

The workflow consists of three sequential analyses:

1. Model comparison and variance partitioning  
2. Differential expression analysis (Tier 1, Tier 2, Tier 2b)  
3. Hybrid inheritance analysis (Tier 3)  

---

## 1. Model Comparison and Variance Partitioning

This analysis evaluates alternative DESeq2 modelling frameworks to determine the most appropriate model for downstream differential expression.

Gene-level counts are analysed under condition, additive, and interaction models, and compared using likelihood ratio tests (LRTs) and variance partitioning. Genes with significant interaction effects are extracted for downstream use.

### Inputs

- Gene-level abundance matrix  
- Sample metadata  

### Outputs

- Model comparison statistics (LRT results)  
- Variance partitioning summaries  
- List of genes with significant interaction effects  

### Results

Full analysis report (code, plots, and summary tables):  

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/DE_reports/DE_model_comparison.html  

---

## 2. Differential Expression (Tier 1, Tier 2, Tier 2b)

This analysis performs gene-level differential expression using the additive model selected in Step 1:

~ temperature + origin + length  

Pairwise contrasts are conducted across temperature and origin to define gene sets representing shared and divergent transcriptional responses.

### Inputs

- Gene-level abundance matrix  
- Sample metadata  
- Interaction gene list (from Step 1)  

### Outputs

- Differential expression results for all contrasts  
- MA plots and Venn diagrams  
- Tier 1, Tier 2, and Tier 2b gene sets  

### Results

Full analysis report (code, plots, and summary tables):  

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/DE_reports/Tier_1_2_DE.html  

---

## 3. Hybrid Inheritance Analysis (Tier 3)

This analysis characterises hybrid gene expression patterns by assigning genes to inheritance categories, including conserved, additive, parent-like, and misexpressed expression.

### Inputs

- Isoform-level abundance matrix  
- Sample metadata  

### Outputs

- Isoform-level differential expression results  
- Expression classification tables  
- Gene-level Tier 3 gene sets  

### Results

Full analysis report (code, plots, and summary tables):  

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/DE_reports/Tier3_DE.html  

---

## Environment

Each analysis documents its required libraries and package versions within the corresponding results report.
