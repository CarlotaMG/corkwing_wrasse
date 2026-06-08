 Differential Expression

This step identifies gene expression patterns associated with temperature, population, and hybrid inheritance in *Symphodus melops*.

The workflow consists of three sequential analyses:

1. Model comparison and variance partitioning  
2. Differential expression analysis (Tier 1, Tier 2, Tier 2b)  
3. Hybrid inheritance analysis (Tier 3)  

---

## Gene Set Framework

Differential expression results were interpreted using a structured framework that groups genes into biologically meaningful categories based on their expression patterns across temperature treatments and population origins.

Gene sets were defined as follows:

- **Tier 1: Shared temperature-responsive genes**  
  Genes consistently regulated by temperature across all origins.

- **Tier 2: Population divergence**  
  Genes with constitutive differences between western and southern populations.

- **Tier 2b: Local thermal adaptation candidates**  
  Genes showing both baseline divergence and temperature-dependent interaction effects.

- **Tier 3: Hybrid expression inheritance**  
  Genes classified based on hybrid expression patterns, including additive, parent-like, and misexpressed categories.

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

Each analysis documents its required libraries and package versions within the corresponding analysis report.
