# Expression Trajectories

This step investigates patterns of gene expression across temperature treatments in Southern, Western, and Hybrid corkwing wrasse. The workflow combines PCA trajectory analyses, hierarchical clustering, and population divergence analyses to examine temperature-response patterns in gene sets identified through previous differential expression analyses.

PCA was used to visualize trajectories across temperatures, hierarchical clustering was used to group genes with similar expression profiles, and population divergence analyses were used to quantify how differences between Southern and Western fish change across the thermal gradient. Bootstrap resampling was used to estimate confidence intervals around population divergence metrics.

## Inputs

- Gene expression matrix
- Sample metadata
- Gene sets identified through differential expression analyses
- Functional annotation table

## Outputs

- PCA trajectory plots and trajectory summaries
- Gene expression clusters and cluster profile visualizations
- Annotated cluster membership tables
- Individual gene trajectory plots
- South-West expression divergence plots with bootstrap confidence intervals

## Results

Full analysis report (code, plots, and summary tables):

https://carlotamg.github.io/corkwing_wrasse/chapter1_rnaseq/expression_trajectories.html

## Environment

Required libraries and package versions are documented in the analysis report.
