#! /bin/bash

# align trimmed reads to E coli and call variants

# download reference genome
mkdir -p data/ref_genome
curl -L \
  -o data/ref_genome/ecoli_rel606.fasta.gz \
  ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz

#unzip the .gz files
gunzip data/ref_genome/ecoli_rel606.fasta.gz

# Index the reference genome
module load BWA/0.7.18-GCCcore-13.3.0
bwa index data/ref_genome/ecoli_rel606.fasta

# Make output directories
mkdir -p results/sam results/bam results/bcf results/vcf

module load BWA/0.7.18-GCCcore-13.3.0
module load SAMtools/1.23.1-GCC-13.3.0
module load BCFtools/1.23.1-GCC-13.3.0

for fwd in data/trimmed_fastq/*_1_paired.fastq.gz
do
sample=$(basename "$fwd" _1_paired.fastq.gz)
    echo "Processing sample $sample"

    rev="data/trimmed_fastq/${sample}_2_paired.fastq.gz"

    #Align
    bwa mem data/ref_genome/ecoli_rel606.fasta "$fwd" "$rev" > results/sam/${sample}.sam

    #Convert SAM → BAM
    samtools view -S -b results/sam/${sample}.sam > results/bam/${sample}.bam

    #Sort BAM
    samtools sort results/bam/${sample}.bam -o results/bam/${sample}.sorted.bam

    #Index BAM
    samtools index results/bam/${sample}.sorted.bam

    #Variant calling
    bcftools mpileup -Ou -f data/ref_genome/ecoli_rel606.fasta results/bam/${sample}.sorted.bam \
        | bcftools call -mv -Oz -o results/vcf/${sample}.vcf.gz

    #Index VCF
    bcftools index results/vcf/${sample}.vcf.gz
done
