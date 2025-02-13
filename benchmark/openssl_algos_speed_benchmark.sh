#!/usr/bin/env bash

# Get OpenSSL from PATH
OPENSSL=$(which openssl)
OPENSSL_VER=$(${OPENSSL} version)

results_dir="$(date +"%M_%H_%Y_%m_%d")"
mkdir -p "$results_dir"
pushd "$results_dir"

tar cvf openssl_oqs.tar.gz $(dirname $(dirname $OPENSSL))

# --- KEM Algorithm Processing ---

kem_raw_file="kem_raw.txt"
kem_csv_file="kem.csv"

# Check for OQS Provider (exit if not found)
if ! openssl list -providers | grep oqsprovider > /dev/null 2>&1; then
    echo "Error: OQS Provider not found. Ensure it's installed and configured."
    exit 1
fi

${OPENSSL} speed -kem-algorithms > "$kem_raw_file"

# Extract KEM data
header_line=$(grep -n "^[[:space:]]*keygen" "$kem_raw_file" | cut -d: -f1)
tail -n +"$((header_line+1))" "$kem_raw_file" | awk '
BEGIN { FS = "[[:space:]]+"; OFS=","; }
{
  gsub(/^[[:space:]]+/, "", $0);
  for (i = 1; i <= NF; i++) { $i = trim($i); }
  print;
}
function trim(str) {
    gsub(/^[[:space:]]+/, "", str);
    gsub(/[[:space:]]+$/, "", str);
    return str;
}
' > "$kem_csv_file"
sed -i "1iAlgorithm,keygen,encaps,decaps,keygens/s,encaps/s,decaps/s" "$kem_csv_file"


# --- Signature Algorithm Processing ---

sig_raw_file="signature_raw.txt"
sig_csv_file="signature.csv"

> "$sig_raw_file" # Clear the output file

# Extract OQS signature algorithm names
signature_algorithms=$(openssl list -signature-algorithms | grep oqs | awk -F'[{}, ]' '{
    for (i=0; i<=NF; i+=1) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); 
        if ($i != "" && !match($i, /^[0-9]+(\.[0-9]+)+/) && !match($i, /\{/)) {
            split($i, a, / /); 
            print a[1] 
            break;
        }
    }
}')

# Test speed for OQS algos
for algo in $signature_algorithms; do
  result=$(openssl speed "$algo") 
  echo "$result" >> "$sig_raw_file"
done

# Test speed for classical algos
openssl speed -signature-algorithms >> "$sig_raw_file"

# Extract Signature Data
awk '
/^built on:/ {next} 
NF > 6 && $1 ~ /^[a-zA-Z0-9_]+$/ { 
    algorithm = $1
    printf("%s,%s,%s,%s,%s,%s,%s\n", algorithm, $2, $3, $4, $5, $6, $7) >> "'"$sig_csv_file"'"
}
' "$sig_raw_file"

sed -i "1iAlgorithm,Keygen Time (s),Sign Time (s),Verify Time (s),Keygens/s,Sign/s,Verify/s" "$sig_csv_file"

if [ $(cat $sig_csv_file | wc -l) -eq 0 ] || [ $(cat $kem_csv_file | wc -l) -eq 0 ]; then
    echo "An empty file was generated!\nKeeping raw data for debug: $sig_raw_file $kem_raw_file"
    exit 1
fi

# Cleanup
rm $sig_raw_file
rm $kem_raw_file

echo "KEM data saved to $kem_csv_file"
echo "Signature data saved to $sig_csv_file"

