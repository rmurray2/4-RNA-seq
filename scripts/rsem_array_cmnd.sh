#!/bin/bash -l
# created: Feb 2, 2020
#author rmurray
#SBATCH -J rsem_calculate_expression
#SBATCH -o OUT/rsem_calculate_expression_out_%j.txt
#SBATCH -e ERROR/rsem_calculate_expression_err_%j.txt
#SBATCH --partition=large
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4000
#SBATCH --mail-type=END

source scripts/command_utility.sh
module load gcc star r-env rstudio perl gcc boost mpich rsem/1.3.2

if [ ! -d "$2" ]
 then
      mkdir $2
 fi
   
for my_file in $1/*.{,fq.gz}
do
if [  -f $my_file ]                                                                                                                                                                                                                           
then
        filename="${my_file##*/}"
        filename="${filename%.*}"
  echo "rsem-calculate-expression -p 8 --strandedness forward --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin --star-gzipped-read-file $my_file rsem_indx/rsem_ref $2/rsem_count_$filename" >> commands/$num_cmnds"_RSEM_calculate_expression"$1_commands.txt                                                                                                                                                                                                           
fi
done  

sbatch_commandlist -t 12:00:00 -mem 24000 -jobname rsem_expression_array -threads 8  -commands commands/$num_cmnds"_RSEM_calculate_expression"$1_commands.txt

#name=$(sed -n ${SLURM_ARRAY_TASK_ID}p namelist)
#justname=$(sed -n ${SLURM_ARRAY_TASK_ID}p justnamelist)
#echo "rsem-calculate-expression -p 8 --strandedness forward --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin --star-gzipped-read-file $name rsem_indx/rsem_ref $2/$justname" >> commands/$num_cmnds"_rsem_calculate_expression".txt
#rsem-calculate-expression -p 8 --strandedness forward --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin --star-gzipped-read-file ${name} rsem_indx/rsem_ref $2/${justname}


#/users/murrayry/RSEM-1.3.1/rsem-calculate-expression -p 8 --calc-ci --strandedness forward --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin --star-gzipped-read-file --fragment-length-mean 81 sortMeRna/non_rRna_trimmed_5ug6h-8-S-R_combined_ctrl.good.fq.gz rs    em_indx/rsem_ref rsem_counts2/rsem_count_non_rRna_trimmed_5ug6h-8-S-R_combined_ctrl.good.fq
