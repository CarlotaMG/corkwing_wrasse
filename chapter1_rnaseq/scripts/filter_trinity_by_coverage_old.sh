#!/bin/bash

input="$1"
output="${2:-results/test_filtered_summary.tsv}"
threshold="${3:-90}"

# Ensure the output directory exists
mkdir -p "$(dirname "$output")"

awk -v threshold="$threshold" '
BEGIN {
    FS = OFS = "\t"
    print "Starting processing..."
}
{
    # Print current line for debugging
    print "Checking line:", $0
    print "Column 15 should be mRNA:", $15
    
    # Check if column 15 matches "mRNA"
    if ($15 == "mRNA") {
        print "Processing mRNA entry:", $0
        
        # Extract and validate coordinate numerical integrity
        trinity_id = $4
        trinity_start = $2 + 0
        trinity_end = $3 + 0
        trinity_len = trinity_end - trinity_start + 1
        
        print "Trinity coordinates:", trinity_start, trinity_end, trinity_len
        
        gff_start = $16 + 0
        gff_end = $17 + 0

        print "GFF coordinates:", gff_start, gff_end

        # Calculate overlap
        overlap_start = (trinity_start > gff_start) ? trinity_start : gff_start
        overlap_end = (trinity_end < gff_end) ? trinity_end : gff_end
        overlap_len = overlap_end - overlap_start + 1
        
        print "Calculated overlap:", overlap_start, overlap_end, overlap_len
        
        # Check positive overlap and proceed
        if (overlap_len <= 0 || trinity_len <= 0) {
            next
        }
        
        # Calculate coverage percentage
        coverage_pct = (overlap_len / trinity_len) * 100
        print "Coverage percentage:", coverage_pct
        
        if (coverage_pct > best_cov[trinity_id]) {
            best_cov[trinity_id] = coverage_pct
        }
        
        # Extract metadata using regex
        match($9, /ID=([^;]+)/, id_arr)
        match($9, /Parent=([^;]+)/, parent_arr)
        match($9, /Ontology_term=([^;]+)/, go_arr)

        transcript_id[trinity_id] = id_arr[1]
        gene_id[trinity_id] = parent_arr[1]
        go_terms[trinity_id] = go_arr[1]
    } else {
        print "Line does not represent mRNA: ", $0
    }
}
END {
    # Print header information
    print "Trinity_ID", "GFF_Transcript", "Gene_ID", "Coverage_%", "GO_Terms"
    
    # Iterate over collected data and apply threshold filtering
    for (t in best_cov) {
        if (best_cov[t] >= threshold) {
            tid = transcript_id[t] ? transcript_id[t] : "NA"
            gid = gene_id[t] ? gene_id[t] : "NA"
            goterms = go_terms[t] ? go_terms[t] : "NA"
            print t, tid, gid, best_cov[t], goterms
        }
    }
    print "Processing complete."
}
' "$input" > "$output"
