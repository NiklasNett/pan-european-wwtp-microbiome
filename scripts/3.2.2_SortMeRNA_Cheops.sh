#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=3gb
#SBATCH --time=35:00:00
#SBATCH --job-name=SortMeRNA
#SBATCH --error=/scratch/nnett2/SortMeRNA-%x-%j.err
#SBATCH --output=/scratch/nnett2/SortMeRNA-%x-%j.out
#SBATCH --account=ag-bonkowski
#SBATCH --mail-type=ALL
#SBATCH --mail-user=nnett2@smail.uni-koeln.de

# Author: Niklas Nett
# Created: 2024-11-27
# Last updated: 2025-03-20

# Purpose: Run SortMeRNA on a single FASTA file to extract rRNA sequences.
#          Designed for batch submission via SLURM. One accession per job.
#          Includes conda environment setup, database references, and output transfer.
# Input:   $1 = Path to input FASTA file (e.g., *_combined.trim.contigs.fasta)
#          $2 = Output working directory (temporary scratch folder)
# Output:  *_rRNA.fa file containing aligned rRNA sequences (moved to final output directory)

# Input arguments
FastaFile="$1"
ScratchOutputDir="$2"
ScratchBaseDir=$(dirname "$ScratchOutputDir")  # Base directory for scratch folder

# Prepare modules and environment
module purge
module load miniconda/py38_4.9.2
conda activate /opt/rrzk/software/conda-envs/sortmerna-4.3.4

# Run SortMeRNA
# set paths to refrence Databanks
# set path to Fasta-files and output/working directories
# set parameters: 
# fastx = keep same file type like input file
# num_alignments = max. number of alignment per read
# -e = sets E-value threshold (-e 0.1 = only alignments ≤ 0.1)
base_name=$(basename "$FastaFile" .fasta)
sortmerna --ref /projects/ag-bonkowski/Databases/sortmerna/silva-bac-16s-id90.fasta \
          --ref /projects/ag-bonkowski/Databases/sortmerna/silva-bac-23s-id98.fasta \
          --ref /projects/ag-bonkowski/Databases/sortmerna/silva-euk-18s-id95.fasta \
          --ref /projects/ag-bonkowski/Databases/sortmerna/silva-arc-16s-id95.fasta \
          --ref /projects/ag-bonkowski/Databases/sortmerna/silva-euk-28s-id98.fasta \
          --ref /projects/ag-bonkowski/Databases/sortmerna/silva-arc-23s-id98.fasta \
          --reads "$FastaFile" \
          --workdir "$ScratchOutputDir" \
          --aligned "${ScratchOutputDir}/${base_name}_rRNA" \
          --other "${ScratchOutputDir}/${base_name}_non_rRNA" \
          --fastx --num_alignments 1 --threads 4 -e 0.1 -v || { echo "SortMeRNA failed!"; exit 1; }


# create output directory for results and move them there
OutputDir="/scratch/nnett2/sortmerna_results_italy"
mkdir -p "$OutputDir"
echo "Moving results for $base_name to $OutputDir"
mv "${ScratchOutputDir}"/*_rRNA.fa "$OutputDir/"

conda deactivate

