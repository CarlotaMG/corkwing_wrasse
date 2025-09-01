#!/bin/bash

input_file="$1"
output_file="$2"
threshold=90

if [ -z "$input_file" ] || [ -z "$output_file" ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

awk -v threshold="$threshold" -F '\t' '

function extract_metadata(info, pattern) {
    match(info, pattern, arr)
    return arr[1] ? arr[1] : "NA"
}

BEGIN {
    print "Trinity_ID\tGFF_Transcript\tGene_ID\tCoverage_%\tGO_Terms" > "'"${output_file}"'"
}

{
    # Print entire line for examination
    print "Processing:", $0

    if ($15 == "mRNA") {
        print "mRNA line:", $0  # Confirmed mRNA line

        trinity_start = $2 + 0
        trinity_end = $3 + 0
        trinity_length = trinity_end - trinity_start + 1

        gff_start = $17 + 0
        gff_end = $18 + 0

        overlap_start = (trinity_start > gff_start ? trinity_start : gff_start)
        overlap_end = (trinity_end < gff_end ? trinity_end : gff_end)
        overlap_length = overlap_end - overlap_start + 1
        coverage_percentage = (overlap_length / trinity_length) * 100

        print "Calculated overlap:", overlap_length, "Coverage:", coverage_percentage

        if (coverage_percentage >= threshold && overlap_length > 0) {
            transcript_id = extract_metadata($21, /ID=([^;]+)/)
            gene_id = extract_metadata($21, /Parent=([^;]+)/)
            go_terms = extract_metadata($21, /Ontology_term=([^;]+)/)

            print $4 "\t" transcript_id "\t" gene_id "\t" coverage_percentage "\t" go_terms >> "'"${output_file}"'"
            print "Entry added:", $4, transcript_id, gene_id, coverage_percentage, go_terms
        }
    }
}
' "$input_file"


