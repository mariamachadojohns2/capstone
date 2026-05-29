#!/bin/bash

#Count how many reads are in the raw FASTQ files
for f in data/untrimmed_fastq/*.fastq.gz
do
    sample=$(basename "$f")
    echo -n "$sample: "
    zcat "$f" | echo $((`wc -l`/4))
done

#Count how many reads are in the trimmed paired FASTQ files
for f in data/trimmed_fastq/*_paired.fastq.gz
do
    sample=$(basename "$f")
    echo -n "$sample: "
    zcat "$f" | echo $((`wc -l`/4))
done

#Count how many reads are aligned to the genome
module load SAMtools/1.23.1-GCC-13.3.0

for bam in results/bam/*.sorted.bam
do
    sample=$(basename "$bam" .sorted.bam)
    echo -n "$sample: "
    # Count only mapped reads
    samtools view -c -F 0x4 "$bam"
done

#Count variant sites per sample
module load BCFtools/1.23.1-GCC-13.3.0

for vcf in results/vcf/*.vcf.gz
do
    sample=$(basename "$vcf" .vcf.gz)
    echo -n "$sample: "
    bcftools view -H "$vcf" | wc -l
done

#To create a tidy data summary table:
## For raw read counts:
echo -e "Sample\tRaw_Reads" > raw_counts.tsv

for r1 in data/untrimmed_fastq/*_1.fastq.gz
do
    sample=$(basename "$r1" _1.fastq.gz)
    r2="data/untrimmed_fastq/${sample}_2.fastq.gz"

    # Count lines in each file
    r1_lines=$(zcat "$r1" | wc -l)
    r2_lines=$(zcat "$r2" | wc -l)

    # Convert total lines to read count
    total_reads=$(((r1_lines + r2_lines) / 4))

    echo -e "${sample}\t${total_reads}" >> raw_counts.tsv
done

## For trimmed read counts:
echo -e "Sample\tTrimmed_Reads" > trimmed_counts.tsv

for r1 in data/trimmed_fastq/*_1_paired.fastq.gz
do
    sample=$(basename "$r1" _1_paired.fastq.gz)
    r2="data/trimmed_fastq/${sample}_2_paired.fastq.gz"

    # Count lines in each file
    r1_lines=$(zcat "$r1" | wc -l)
    r2_lines=$(zcat "$r2" | wc -l)

    # Convert total lines to read count
    total_reads=$(((r1_lines + r2_lines) / 4))

    echo -e "${sample}\t${total_reads}" >> trimmed_counts.tsv
done

# Count aligned reads per sample
module load SAMtools/1.23.1-GCC-13.3.0

echo -e "Sample\tAligned_Reads" > aligned_counts.tsv
for bam in results/bam/*.sorted.bam
do
    sample=$(basename "$bam" .sorted.bam)
    # Count mapped reads (exclude unmapped)
    aligned=$(samtools view -c -F 0x4 "$bam")
    echo -e "${sample}\t${aligned}" >> aligned_counts.tsv
done

# Variant sites per sample
module load BCFtools/1.23.1-GCC-13.3.0
echo -e "Sample\tVariant_Sites" > variant_counts.tsv
for vcf in results/vcf/*.vcf.gz
do
    sample=$(basename "$vcf" .vcf.gz)
    variants=$(bcftools view -H "$vcf" | wc -l)
    echo -e "${sample}\t${variants}" >> variant_counts.tsv
done

# Sort all files
sort -k1,1 raw_counts.tsv > raw_counts.sorted.tsv
sort -k1,1 trimmed_counts.tsv > trimmed_counts.sorted.tsv
sort -k1,1 aligned_counts.tsv > aligned_counts.sorted.tsv
sort -k1,1 variant_counts.tsv > variant_counts.sorted.tsv

# Combine all counts into a summary table
{
    # Add the header row at the top of the final table
    echo -e "Sample\tRaw_Reads\tTrimmed_Reads\tAligned_Reads\tVariant_Sites"

    # paste = combine files side-by-side
    # <(tail -n +2 file) = remove the header from each file before pasting
    paste \
        <(tail -n +2 raw_counts.tsv) \
        <(tail -n +2 trimmed_counts.tsv) \
        <(tail -n +2 aligned_counts.tsv) \
        <(tail -n +2 variant_counts.tsv) \
    
    # cut selects only the columns wanted:
    # 1 = Sample
    # 2 = Raw_Reads
    # 4 = Trimmed_Reads
    # 6 = Aligned_Reads
    # 8 = Variant_Sites
    | cut -f1,2,4,6,8

# Redirect everything inside { } into the final summary table
} > summary_table.tsv



