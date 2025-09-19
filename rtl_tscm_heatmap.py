#!/usr/bin/env python3
import sys
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime

if len(sys.argv) < 2:
    print("Usage: python3 rtl_tscm_heatmap.py results.csv")
    sys.exit(1)

infile = sys.argv[1]
outdir = os.path.dirname(infile)
base = os.path.splitext(os.path.basename(infile))[0]

print(f"[*] Loading {infile} ...")
df = pd.read_csv(infile, comment="#", header=None)
# rtl_power CSV format: date, time, hz_low, hz_high, hz_step, samples, dB, dB, ...
df.columns = ["date", "time", "hz_low", "hz_high", "hz_step", "samples"] + \
             [f"bin_{i}" for i in range(len(df.columns)-6)]

# Build spectrogram
power = df[[c for c in df.columns if c.startswith("bin_")]].to_numpy()
freqs = np.linspace(df["hz_low"].iloc[0], df["hz_high"].iloc[0],
                    power.shape[1])
times = pd.to_datetime(df["date"] + " " + df["time"])

plt.figure(figsize=(12,6))
plt.imshow(power.T, aspect="auto", origin="lower",
           extent=[0, len(times), freqs[0]/1e6, freqs[-1]/1e6],
           cmap="viridis")
plt.colorbar(label="dB")
plt.ylabel("Frequency (MHz)")
plt.xlabel("Sweep index")
plt.title(f"Spectrum Heatmap: {base}")
plt.tight_layout()
heatmap_file = os.path.join(outdir, f"{base}_heatmap.png")
plt.savefig(heatmap_file, dpi=200)
plt.close()
print(f"[*] Saved heatmap to {heatmap_file}")

# Candidate detection: flag persistent narrow peaks
avg_power = power.mean(axis=0)
threshold = np.median(avg_power) + 6  # 6 dB above median baseline
candidates = freqs[avg_power > threshold]

cand_file = os.path.join(outdir, f"{base}_candidates.csv")
pd.DataFrame({"freq_hz": candidates, "median_db": avg_power[avg_power > threshold]}
            ).to_csv(cand_file, index=False)
print(f"[*] Saved {len(candidates)} candidate freqs to {cand_file}")
