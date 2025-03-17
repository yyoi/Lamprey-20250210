#!/bin/zsh

# Sample code for MCScanX analysis

# 1. Preparation

# Data
# Download data from NCBI GENOME https://www.ncbi.nlm.nih.gov/datasets/genome/
# Lamprey: GCF_010993605.1
# Human: GCF_009914755.1
# The protein fasta and gff file can be downloaded there.

# Programs
# MCScanX
# See: https://github.com/wyp1125/MCScanX
MCScanX=./set/path/for/MCScanX

# Diamond
# See: https://github.com/bbuchfink/diamond
diamond=./set/path/for/diamond


# 2. Analysis

# Path
lamprey_fasta=./set/path/for/your/lamprey_file.fasta.gz
lamprey_gff=./set/path/for/your/lamprey_file.gff.gz
human_fasta=./set/path/for/your/human_file.fasta.gz
human_gff=./set/path/for/your/human_file.gff.gz

# Transform gff file
# NOTE: It is example. Please modify for your gff data.
# See MCScanX documentation.
zless ${lamprey_gff} | awk '$1 !~ /#/ && $3 == "CDS" {sub(/.+Name=/,"",$9);sub(/;.+/,"",$9); print $1"\t"$9"\t"$4"\t"$5}' > lamprey_mod.gff
zless ${human_gff} | awk '$1 !~ /#/ && $3 == "CDS" {sub(/.+Name=/,"",$9);sub(/;.+/,"",$9); print $1"\t"$9"\t"$4"\t"$5}' > human_mod.gff

# Combind gff file
cat lamprey_mod.gff human_mod.gff > combind.gff

# Combind protein fasta
zcat ${lamprey_fasta} ${human_fasta} > combind.fasta

# DIAMOND
$diamond makedb --in combind.fasta -d combind
$diamond blastp --ultra-sensitive --threads 6 --db combind --query combind.fasta --max-target-seqs 5 --evalue 1e-10 --outfmt 6 --out combind.blast 

# MACScanX
$MACScanX -m 200 -g 0 ./combind
