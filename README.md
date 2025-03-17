# Evolutionaly analysis for lamprey MHC

This pipeline code was an example of the methods used in the following study.

* _in preparation_

## Base calling from Oxford Nanopore data
### Environment
* Mac Studio
    * Chip: M1 Ultra
    * Memory: 128GB
    * OS: macOS Ventura 13.1

### Tools
Install follwoing tools:

* dorado [[1]]
* minimap2 [[2]]
* samtools [[3]]
* bcftools [[4]]
* vcftools [[5]]
* tabix [[6]]

[1]:https://github.com/nanoporetech/dorado
[2]:https://github.com/lh3/minimap2
[3]:https://www.htslib.org/
[4]:https://samtools.github.io/bcftools/
[5]:https://vcftools.sourceforge.net/
[6]:https://www.htslib.org/doc/tabix.html

and download reference genome data, for example:

* lamprey genome (kPetMar1.pri) [[7]]

[7]: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_010993605.1/


### Model download
```bash
#!/bin/zsh

export model=dna_r10.4.1_e8.2_400bps_sup@v5.0.0

dorado download --model $model
```

### Base calling
```bash
#!/bin/zsh

export model=dna_r10.4.1_e8.2_400bps_sup@v5.0.0
export pod5=./set/your/pod5_directory_path
export bam=./set/output/bamfile.ubam

dorado basecaller $model $pod5 > $outfile
```

### Convert bam to fastq
```bash
#!/bin/zsh

export bam=./set/output/bamfile.ubam
export fastq=./set/output/fastq.fastq

samtools fastq --threads 8 $bam | pigz -c > $fastq.gz
```

### Mapping
```bash
#!/bin/zsh

export animal=animalID
export fastq=./set/output/fastq.fastq
export refgenome=./set/your/reference_genome.fasta
export sam=./set/output/samfile.sam

minimap2 -t 8 -ax map-ont $refgenome $fastq.gz > $sam
```

## Variant calling
```bash
#!/bin/zsh

export animal=animalID
export sam=./set/output/samfile.sam

# Comvert sam to bam
samtools view -S -b $sam > ${animal}_aln.bam

# Sort
samtools sort -o ${animal}_aln_sorted.bam ${animal}_aln.bam

# Stats
samtools stats -@ 4 ${animal}_aln_sorted.bam > ${animals}_aln_stats.txt

# Variant calling
bcftools mpileup --threads 16 --max-depth 1000 -Ou -f $refgenome *_aln_sorted.bam | bcftools call --threads 16 -mv -Ob -o lamprey.bcf
```

## Quality contorl (QC) for variants
I removed here:
* low quality (QUAL < 20)
* Excess depth (DP > mean_depth * 2)

```bash
#!/bin/zsh

# Check depth by sample
bcftools stats -s animalID lamprey.bcf > lamprey_stats.txt
plot-vcfstats lamprey_stats.txt -p lamprey_stats_plot

# The following code is example when the average depth was 6.2.

# QC
bcftools filter -s LowQual -e 'QUAL<20 || DP>12.4' $wd/03_VCF/lamprey.bcf -Ob -o lamprey_high_QUAL_Depth.bcf

# Normalize
bcftools norm -f $refgenome lamprey_QC_PASS.vcf.gz -Ob -o lamprey_QC_PASS.norm.bcf

# Remove missing site
vcftools --bcf lamprey_QC_PASS.norm.bcf --max-missing-count 2 --recode-bcf --out lamprey_QC_PASS_delmiss

# Split SNVs and indels. ignore
bcftools view lamprey_QC_PASS_delmiss.recode.bcf -v snps -Oz -o lamprey_QC_PASS_snps.vcf.gz
bcftools view lamprey_QC_PASS_delmiss.recode.bcf -v indels -Oz -o lamprey_QC_PASS_indels.vcf.gz

# Filter adjacent indels and SNPs within 5bp and 2 bp, respectiverly
bcftools filter --IndelGap 5 --SnpGap 2 lamprey_QC_PASS_snps.vcf.gz -Oz -o lamprey_QC_PASS_snps_gap.vcf.gz
bcftools filter --IndelGap 5 --SnpGap 2 lamprey_QC_PASS_indels.vcf.gz -Oz -o lamprey_QC_PASS_indels_gap.vcf.gz

# Make index file for vcf
tabix -p vcf lamprey_QC_PASS_snps_gap.vcf.gz
tabix -p vcf lamprey_QC_PASS_indels_gap.vcf.gz

```

## Analysis
```bash
#!/bin/zsh

# Density
vcftools --gzvcf $wd/04_QC/lamprey_QC_PASS_snps_gap.vcf.gz --SNPdensity 10000 --out lamprey_QC_PASS

# Tajima's D
vcftools --gzvcf $wd/04_QC/lamprey_QC_PASS_snps_gap.vcf.gz --TajimaD 10000 --out lamprey_QC_PASS

# TsTv
vcftools --gzvcf $wd/04_QC/lamprey_QC_PASS_snps_gap.vcf.gz --TsTv 10000 --out lamprey_QC_PASS

# Diversity
vcftools --gzvcf $wd/04_QC/lamprey_QC_PASS_snps_gap.vcf.gz --window-pi 10000 --out lamprey_QC_PASS
```

## MCScanX
See: ./shell/Sample_MCScanX.sh

## OrthoFinder
See: ./shell/Sample_OrthoFinder.sh
