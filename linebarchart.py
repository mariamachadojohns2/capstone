#!/bin/bash

#make line and bar charts
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load summary table
summary = pd.read_csv("summary_table.tsv", sep="\t")


# Convert to tidy format for line chart
summary_long = summary.melt(
    id_vars="Sample",
    value_vars=["Raw_Reads", "Trimmed_Reads", "Aligned_Reads"],
    var_name="Step",
    value_name="Reads"
)

# Ensure correct order on x-axis
order = ["Raw_Reads", "Trimmed_Reads", "Aligned_Reads"]
summary_long["Step"] = pd.Categorical(summary_long["Step"], categories=order, ordered=True)


# Line chart: read counts across pipeline steps
plt.figure(figsize=(10, 6))
sns.lineplot(
    data=summary_long,
    x="Step",
    y="Reads",
    hue="Sample",
    marker="o",
    linewidth=2
)

plt.title("Read Counts Across Pipeline Steps")
plt.xlabel("Processing Step")
plt.ylabel("Number of Reads")
plt.tight_layout()
plt.savefig("reads_line_chart.png", dpi=300)
plt.close()

# Bar chart: variant counts per sample
plt.figure(figsize=(8, 5))
sns.barplot(
    data=summary,
    x="Sample",
    y="Variant_Sites",
    color="steelblue"
)

plt.title("Variant Sites per Sample")
plt.xlabel("Sample")
plt.ylabel("Number of Variant Sites")
plt.tight_layout()
plt.savefig("variant_bar_chart.png", dpi=300)
plt.close()

print("Plots created: reads_line_chart.png and variant_bar_chart.png")
