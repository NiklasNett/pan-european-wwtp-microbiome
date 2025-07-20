#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1gb
#SBATCH --time=10:00:00
#SBATCH --account=ag-bonkowski
#SBATCH --mail-type=ALL
#SBATCH --mail-user=nnett2@smail.uni-koeln.de

# Author: Niklas Nett
# Created: 2024-11-29
# Last updated: 2025-03-20

# Purpose: Run BLASTN against the PR2 eukaryotic rRNA database for a given accession.
#          Designed for batch submission via SLURM. One accession per job.
#          Includes module setup and direct output to results directory
# Input:   - Sample name (ENA Run Accession) passed as argument ($1)
#          - Corresponding FASTA file: *_combined.trim.contigs_rRNA.fa
# Output:  - Tab-delimited BLAST result in PR2 format for the given sample
#          - Output file saved in a specified results folder

# Input arguments
SampleName="$1"
InputDir=/scratch/nnett2/sortmerna_results_italy
Contig="$SampleName"_1_combined.trim.contigs_rRNA.fa

# Create output directory for results
OutputDir=/scratch/nnett2/Blast_PR2_Results_italy/
mkdir -p "$OutputDir"

# Prepare modules
module purge
module load blast+/2.10.0 || { echo "Error: Failed to load BLAST module" >&2; exit 1; }

# Check input file
if [ ! -f "$InputDir/$Contig" ]; then
    echo "Error: Input file $InputDir/$Contig not found!" >&2
    exit 1
fi


# Run BLAST
# set path to PR2 database
# set parameter:
# evalue = sets E-Value threshold
# outfmt = specifies  output format of  BLAST results:
    # 6 = Format 6; tabular format, with custom-selected columns:
        # qseqid = query sequence ID
        # qlen = length of query sequence
        # sacc = subject accession number (from database)
        # bitscore = alignment bit score (measure of alignment quality)
        # evalue = E-value for the alignment
        # length = alignment length
        # nident = number of identical matches
        # pident = percentage identity (percentage of identical matches in the alignment)
# max_target_seqs = how many hits are shown in list       
echo "[$(date)] Starting BLAST for $SampleName with PR2 database..." >&2

blastn -db /projects/ag-bonkowski/Databases/PR2/pr2_v4.13.0_18S_modif1 \
-query "$InputDir/$Contig" \
-evalue 1e-30 \
-out "$OutputDir/${SampleName}_rRNA_Blast_P2.txt" \
-num_threads 4 \
-outfmt "6 qseqid qlen sacc bitscore evalue length nident pident" \
-max_target_seqs 1 || { echo "BLAST failed for $SampleName" >&2; exit 1; }


echo "[$(date)] Completed BLAST for $SampleName." >&2