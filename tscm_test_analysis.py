#!/usr/bin/env python3
"""
Test analysis script for RTL-SDR TSCM test sweep.

- Scans all CSV files in a given folder
- Generates a heatmap PNG per band
- Generates candidate frequency CSV per band
- Safe to include in GitHub for demo/testing
"""

import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from glob import glob

# Folder containing CSVs (default: latest test sweep)
if len(sys.argv) > 1:
    folder = sys.argv[1]
else:
    # auto-find latest test folder
    test_folders = sorted(glob("tscm_test_*"), reverse=True)
    if not test_folders:
        print("No test sweep folders found. Run tscm_test_sweep.sh first.")
        sys.exit(1)
    folder = test_folders[0]

print(f"[*] Analyzing CSVs in {folder}")

csv_files = glob(os.path.join(folder, "*.csv"))
csv_files = [f for f in csv_files if not f.endswith("_candidates.csv")]

if not csv_files:
    print("No CSV files to analyze.")
    sys.exit(1)

for csv_file in csv_files:
    base = os.path.splitext(os.path.basename(csv_file))[0]
    print(f"[*] Processing {csv_file}")

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
    heatmap_file = os.path.join(folder, f"{base}_heatmap.png")
    plt.savefig(heatmap_file, dpi=200)
    plt.close()
    print(f"[*] Saved heatmap: {heatmap_file}")

    # Candidate detection
    avg_power = power.mean(axis=0)
    threshold = np.median(avg_power) + 6  # 6 dB above median
    candidates = freqs[avg_power > threshold]

    cand_file = os.path.join(folder, f"{base}_candidates.csv")
    pd.DataFrame({"freq_hz": candidates, "median_db": avg_power[avg_power > threshold]}).to_csv(cand_file, index=False)
    print(f"[*] Saved {len(candidates)} candidate(s) -> {cand_file}")

print("[*] Test analysis complete.")
