#!/bin/bash
# Quick test sweep for RTL-SDR, 1 minute per band
# Safe to put on GitHub as a test/demo

TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUTDIR="tscm_test_${TS}"
mkdir -p "$OUTDIR"

# Sweep duration per band (seconds)
DURATION=60

# Bands to test: start:stop:step
BANDS=(
  "70M:600M:100k"
  "600M:1000M:100k"
  "1000M:1700M:100k"
)

# Create simple manifest
MANIFEST="$OUTDIR/results_manifest.txt"
echo "Test Sweep started at: $(date -u)" > "$MANIFEST"
echo "Duration per band (s): $DURATION" >> "$MANIFEST"
echo "Bands:" >> "$MANIFEST"
for B in "${BANDS[@]}"; do
    echo "  $B" >> "$MANIFEST"
done
echo "Output folder: $OUTDIR" >> "$MANIFEST"
echo "-----------------------------" >> "$MANIFEST"

# Loop through bands
for B in "${BANDS[@]}"; do
  FNAME=$(echo $B | tr ':' '_').csv
  echo "[*] Sweeping $B for $DURATION seconds ..."
  echo "Sweeping $B at $(date -u)" >> "$MANIFEST"

  rtl_power -f $B -i 10 -g 20 -e $DURATION -F csv "$OUTDIR/$FNAME"

  echo "Finished $B at $(date -u)" >> "$MANIFEST"
done

echo "[*] Test sweep complete. Results in $OUTDIR/"
