#! /bin/bash

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
    echo "$sample"
    samtools flagstat "$bam" | grep "mapped (" 
done

#Count variant sites per sample
module load BCFtools/1.23.1-GCC-13.3.0

for vcf in results/vcf/*.vcf.gz
do
    sample=$(basename "$vcf" .vcf.gz)
    echo -n "$sample: "
    bcftools view -H "$vcf" | wc -l
done
