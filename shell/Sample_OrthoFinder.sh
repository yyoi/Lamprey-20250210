#!/bin/zsh

# Sample code for OrthoFinder analysis

# Data
# Download data from NCBI GENOME https://www.ncbi.nlm.nih.gov/datasets/genome/
# Protein fasta retreved from NCBI genome
# * human (T2T-CHM13v2.0)
# * lamprey (kPetMar1.pri)
# * amphioxus (klBraLanc5.hap2)
# * shark (sHemOce1.pat.X.cur)
# * zebrafish (GRCz11)
# Move all protein fasta file into ./input derectory.

# Hemiscyllium ocellatum (epaulette shark) (sHemOce1.pat.X.cur) had the highest BUSCO in the NCBI shark genome

# Programs
# OrthoFinder
# See: https://github.com/davidemms/OrthoFinder

# Test run
docker pull davidemms/orthofinder
docker run -it --rm davidemms/orthofinder orthofinder -h
docker run --platform linux/amd64 --ulimit nofile=1000000:1000000 -it -v ${PWD} --rm davidemms/orthofinder orthofinder -f /opt/OrthoFinder_source/ExampleData

# Run
docker run --platform linux/amd64 --ulimit nofile=1000000:1000000 -it --rm -v ${PWD}/input:/input davidemms/orthofinder orthofinder -f /input
