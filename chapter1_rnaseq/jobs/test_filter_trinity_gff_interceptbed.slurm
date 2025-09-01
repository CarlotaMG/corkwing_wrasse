#!/bin/bash
#SBATCH --account=nn12014k
#SBATCH --job-name=test_filter_trinity
#SBATCH --output=/cluster/projects/nn12014k/corkwing_wrasse/chapter1_rnaseq/jobs/logs/test_filter_trinity_%j.out
#SBATCH --error=/cluster/projects/nn12014k/corkwing_wrasse/chapter1_rnaseq/jobs/logs/test_filter_trinity_%j.err  # Error log
#SBATCH --time=00:05:00                            # Max runtime
#SBATCH --mem=2G                                   # Memory allocation
#SBATCH --cpus-per-task=1                          # Number of CPU cores
#SBATCH --partition=normal                         # Partition to run on

# Move to the project root directory
cd /cluster/projects/nn12014k/corkwing_wrasse/chapter1_rnaseq

# Create a small test file (first 100 lines of the intersected BED file)
tail -n 25 data/mapping_transcriptome/intersected_gff_with_transcriptomebam.bed > results/test_intersect.bed

# Run the filtering script with input and output paths
bash scripts/filter_trinity_by_coverage.sh results/test_intersect.bed results/test_filtered_summary.tsv
