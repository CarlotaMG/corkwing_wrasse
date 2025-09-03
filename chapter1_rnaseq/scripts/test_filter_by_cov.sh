#!/bin/bash

input="$1"
basename=$(basename "$input" .bed)
output="${2:-${basename}_summary.tsv}"
threshold="${3:-90}"

mkdir -p "$(dirname "$output")"

awk -v threshold="$threshold" '
BEGIN {
    FS = OFS = "\t"
}
{
    if ($15 == "mRNA") {
        trinity_id = $4
        trinity_start = $2 + 0
        trinity_end = $3 + 0
        trinity_len = trinity_end - trinity_start + 1

        gff_start = $16 + 0
        gff_end = $17 + 0

        overlap_start = (trinity_start > gff_start) ? trinity_start : gff_start
        overlap_end = (trinity_end < gff_end) ? trinity_end : gff_end
        overlap_len = overlap_end - overlap_start + 1

        if (overlap_len <= 0 || trinity_len <= 0) {
            next
        }

        coverage_pct = (overlap_len / trinity_len) * 100

        if (coverage_pct > best_cov[trinity_id]) {
            best_cov[trinity_id] = coverage_pct
        }

        match($21, /ID=([^;]+)/, id_arr)
        match($21, /Parent=([^;]+)/, parent_arr)
        match($21, /Ontology_term=([^;]+)/, go_arr)
        match($21, /Dbxref=([^;]+)/, dbxref_arr)
        match($21, /uniprot_id=([^;]+)/, uniprot_arr)

        transcript_id[trinity_id] = id_arr[1]
        gene_id[trinity_id] = parent_arr[1]
        go_terms[trinity_id] = go_arr[1]
        dbxref[trinity_id] = dbxref_arr[1]
        uniprot[trinity_id] = uniprot_arr[1]
    }
}
END {
    print "Trinity_ID", "GFF_Transcript", "Gene_ID", "Coverage_%", "GO_Terms", "Dbxref", "UniProt_ID"
    for (t in best_cov) {
        if (best_cov[t] >= threshold) {
            tid = transcript_id[t] ? transcript_id[t] : "NA"
            gid = gene_id[t] ? gene_id[t] : "NA"
            goterms = go_terms[t] ? go_terms[t] : "NA"
            dbx = dbxref[t] ? dbxref[t] : "NA"
            uni = uniprot[t] ? uniprot[t] : "NA"
            print t, tid, gid, best_cov[t], goterms, dbx, uni
        }
    }
}
' "$input" > "$output"
