#!/bin/bash -l
# created: Feb 2, 2020
# author: rmurray
#SBATCH -J rsem_prepare_reference
#SBATCH -o OUT/rsem_prepare_genome_out_%j.txt
#SBATCH -e ERROR/rsem_prepare_genome_err_%j.txt
#SBATCH -p large 
#SBATCH -n 8
#SBATCH -t 12:00:00
#SBATCH --mem-per-cpu=48000
#SBATCH --mail-type=END

source scripts/command_utility.sh
num_cmnds=$( cmnds_in_file )

module load gcc star r-env rstudio perl

if [ ! -d rsem_indx  ]; then
	
	mkdir rsem_indx
	overhang=$(( maxReadLength - 1 ))

	echo "/users/murrayry/RSEM-1.3.1/rsem-prepare-reference --gtf $gene_annotation --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin -p 8 --star-sjdboverhang $overhang $genome_file rsem_indx/rsem_ref" >> commands/$num_cmnds"_rsem_prepare_reference".txt

	/users/murrayry/RSEM-1.3.1/rsem-prepare-reference --gtf $gene_annotation --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin -p 8 --star-sjdboverhang $overhang $genome_file rsem_indx/rsem_ref

	mv *_out_*txt OUT
	mv *_err_*txt ERROR

fi
#TODO:
#add check to see if genome is prepared, 

#THIS doesn't work on sbatch_commandlist for some reason
#if [ ! -d "$2" ]
#   then
#   mkdir $2
#fi
#
#for my_file in $1/*.{,fq.gz}
#do
#if [  -f $my_file ]
#then
#        filename="${my_file##*/}"
#        filename="${filename%.*}"
#  echo "/users/murrayry/RSEM/software/RSEM-1.2.25/rsem-calculate-expression -p 8 --calc-ci --strand-specific --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin --gzipped-read-file $my_file rsem_indx/rsem_ref $2/rsem_count_$filename" >> commands/$num_cmnds"_RSEM_calculate_expression"$1_commands.txt
#fi
#done
#
#sbatch_commandlist -t 12:00:00 -mem 24000 -jobname rsem_expression_array -threads 8  -commands commands/$num_cmnds"_RSEM_calculate_expression"$1_commands.txt
#
#mv *_out_*txt OUT
#mv *_err_*txt ERROR
#
#source scripts/multiqc_slurm.sh
