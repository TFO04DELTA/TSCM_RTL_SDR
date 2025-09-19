#!/bin/bash
# Simple wrapper to run rtl_power sweeps over major bands

TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUTDIR="tscm_results_${TS}"
mkdir -p "$OUTDIR"

# Sweep definitions: start:stop:step
BANDS=(
  "70M:600M:100k"
  "600M:1000M:100k"
  "1000M:2400M:100k"
)

for B in "${BANDS[@]}"; do
  FNAME=$(echo $B | tr ':' '_').csv
  echo "[*] Sweeping $B ..."
  rtl_power -f $B -i 10 -g 20 -e 900 -F csv "$OUTDIR/$FNAME"
done

echo "[*] All sweeps complete. Results in $OUTDIR/"
