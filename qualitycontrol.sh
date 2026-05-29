#!/bin/bash

# Download FastQ sample files
mkdir -p data/untrimmed_fastq
cd data/untrimmed_fastq

curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_2.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_2.fastq.gz

# Perform basic quality control on FASTQ files

# Run FASTQC on untrimmed reads
ml FastQC/0.12.1-Java-11

mkdir -p results/untrimmed_fastqc
fastqc data/untrimmed_fastq/*.fastq.gz -o results/untrimmed_fastqc


module load MultiQC/1.28-foss-2024a

multiqc results/untrimmed_fastqc -o results/untrimmed_multiqc

# trim fastq files with trimmomatic
module load Trimmomatic/0.39-Java-17
mkdir -p data/trimmed_fastq

for fwd in data/untrimmed_fastq/*_1.fastq.gz
do
    sample=$(basename "$fwd" _1.fastq.gz)
    echo "Processing $sample"

    rev="data/untrimmed_fastq/${sample}_2.fastq.gz"

    trimmomatic PE \
        "$fwd" "$rev" \
        "data/trimmed_fastq/${sample}_1_paired.fastq.gz" \
        "data/trimmed_fastq/${sample}_1_unpaired.fastq.gz" \
        "data/trimmed_fastq/${sample}_2_paired.fastq.gz" \
        "data/trimmed_fastq/${sample}_2_unpaired.fastq.gz" \
        ILLUMINACLIP:$EBROOTTRIMMOMATIC/adapters/TruSeq3-PE.fa:2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

# Run FASTQC on trimmed reads only
mkdir -p results/trimmed_fastqc

module load FastQC/0.12.1-Java-11
fastqc data/trimmed_fastq/*_paired.fastq.gz -o results/trimmed_fastqc

module load MultiQC/1.28-foss-2024a
multiqc results/trimmed_fastqc -o results/trimmed_multiqc
