#!/bin/bash
# Demo test script: quick sweep + analysis for RTL-SDR TSCM
# Safe for GitHub; 1 min per band test

set -euo pipefail

# -----------------------------
# Config
# -----------------------------
TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUTDIR="tscm_demo_${TS}"
mkdir -p "$OUTDIR"

DURATION=60  # seconds per band
BANDS=(
  "70M:600M:100k"
  "600M:1000M:100k"
  "1000M:1700M:100k"
)

MANIFEST="$OUTDIR/results_manifest.txt"
echo "Demo Test Sweep started at: $(date -u)" > "$MANIFEST"
echo "Duration per band (s): $DURATION" >> "$MANIFEST"
echo "Bands:" >> "$MANIFEST"
for B in "${BANDS[@]}"; do
    echo "  $B" >> "$MANIFEST"
done
echo "Output folder: $OUTDIR" >> "$MANIFEST"
echo "-----------------------------" >> "$MANIFEST"

# -----------------------------
# Sweep
# -----------------------------
for B in "${BANDS[@]}"; do
  FNAME=$(echo $B | tr ':' '_').csv
  echo "[*] Sweeping $B for $DURATION seconds ..."
  echo "Sweeping $B at $(date -u)" >> "$MANIFEST"

  rtl_power -f $B -i 10 -g 20 -e $DURATION -F csv "$OUTDIR/$FNAME"

  echo "Finished $B at $(date -u)" >> "$MANIFEST"
done

# -----------------------------
# Analysis
# -----------------------------
echo "[*] Starting analysis..."
for csv_file in "$OUTDIR"/*.csv; do
  # skip candidates CSV if rerun
  [[ $csv_file == *_candidates.csv ]] && continue
  base=$(basename "$csv_file" .csv)
  echo "[*] Processing $csv_file"

  python3 - <<EOF
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

csv_file = "$csv_file"
folder = os.path.dirname(csv_file)
base = os.path.splitext(os.path.basename(csv_file))[0]

df = pd.read_csv(csv_file, comment="#", header=None)
df.columns = ["date","time","hz_low","hz_high","hz_step","samples"] + \
             [f"bin_{i}" for i in range(len(df.columns)-6)]

power = df[[c for c in df.columns if c.startswith("bin_")]].to_numpy()
freqs = np.linspace(df["hz_low"].iloc[0], df["hz_high"].iloc[0], power.shape[1])

# Heatmap
plt.figure(figsize=(12,6))
plt.imshow(power.T, aspect="auto", origin="lower",
           extent=[0, power.shape[0], freqs[0]/1e6, freqs[-1]/1e6],
           cmap="viridis")
plt.colorbar(label="dB")
plt.xlabel("Sweep index")
plt.ylabel("Frequency (MHz)")
plt.title(f"Spectrum Heatmap: {base}")
plt.tight_layout()
plt.savefig(os.path.join(folder, f"{base}_heatmap.png"), dpi=200)
plt.close()

# Candidate detection
avg_power = power.mean(axis=0)
threshold = np.median(avg_power) + 6
candidates = freqs[avg_power > threshold]
cand_file = os.path.join(folder, f"{base}_candidates.csv")
pd.DataFrame({"freq_hz": candidates, "median_db": avg_power[avg_power > threshold]}).to_csv(cand_file, index=False)
EOF

done

echo "[*] Demo sweep + analysis complete. Results in $OUTDIR/"
