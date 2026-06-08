# Functional Enrichment

This step interprets gene expression patterns by identifying enriched functional categories and pathways across Tier 1, Tier 2, Tier 2b, and Tier 3 gene sets (see [Differential Expression framework](../DE/README.md#gene-set-framework) for definitions).

Functional enrichment integrates differential expression results with ortholog mapping and Gene Ontology (GO) and KEGG pathway databases to characterise the biological processes underlying temperature response, population divergence, and hybrid inheritance.

---

## Overview

Functional enrichment is performed for all gene sets derived from differential expression analyses, including:

- Tier 1 (shared temperature response)  
- Tier 2 (population divergence)  
- Tier 2b (population-specific temperature response)  
- Tier 3 (hybrid inheritance categories)  
- Intersections between tiers  

---

## Inputs

- Gene sets from differential expression:
  - Tier 1, Tier 2, Tier 2b  
  - Tier 3 (misexpressed and parent-like categories)  
  - Tier intersections  

- Functional annotation:
  - eggNOG annotation table  
  - Trinity-to-ortholog mapping  

---

## Outputs

- Ortholog mapping tables and coverage summaries  
- GO enrichment results across Biological Process (BP), Molecular Function (MF), and Cellular Component (CC)  
- KEGG pathway enrichment results  
- Enrichment summaries across all tiers  
- Visualisations (GO plots and pathway dotplots)  

---

## Results

Full analysis report (code, plots, and interpretation):  

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/functional_enrichment.html  

---

## Environment

Required packages and versions are documented within the analysis report.
