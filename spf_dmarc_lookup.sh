#!/bin/bash

# Usage: ./spf_dmarc_lookup.sh domains.txt [output.csv]
# - domains.txt: a text file with one domain per line
# - output.csv: optional output file (default: results.csv)
# Requirements: dig command (available by default on macOS)

input_file="${1:-domains.txt}"
output_file="${2:-results.csv}"

# Get current date in YYYY-MM-DD format
current_date=$(date +%Y-%m-%d)

# Write CSV header
echo "domain,date,spf,dmarc" > "$output_file"

# Read domains from input file, skip empty lines and comments
while IFS= read -r domain || [[ -n "$domain" ]]; do
    [[ -z "$domain" || "$domain" =~ ^# ]] && continue
    
    domain=$(echo "$domain" | xargs)  # trim whitespace
    
    echo "Processing: $domain"
    
    # Lookup SPF: TXT records for the root domain, find one starting with v=spf1
    spf=$(dig TXT "$domain" +short | grep -i '^"v=spf1' | tr -d '"' | paste -sd " " -)
    [[ -z "$spf" ]] && spf="none"
    
    # Lookup DMARC: TXT record for _dmarc subdomain, find one starting with v=DMARC1
    dmarc=$(dig TXT "_dmarc.$domain" +short | grep -i '^"v=DMARC1' | tr -d '"' | paste -sd " " -)
    [[ -z "$dmarc" ]] && dmarc="none"
    
    # Escape commas and quotes in records for CSV safety
    spf_escaped=$(echo "$spf" | sed 's/"/""/g')
    dmarc_escaped=$(echo "$dmarc" | sed 's/"/""/g')
    
    # Append to CSV
    echo "\"$domain\",\"$current_date\",\"$spf_escaped\",\"$dmarc_escaped\"" >> "$output_file"
    
done < "$input_file"

echo "Done! Results saved to $output_file"
