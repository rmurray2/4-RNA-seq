#!/bin/bash -l
# author: murrayry
#SBATCH -J DE_exp
#SBATCH -o OUT/DE_exp_out_%j.txt
#SBATCH -e ERROR/DE_exp_err_%j.txt
#SBATCH -p large
#SBATCH -n 1
#SBATCH -t 0:30:00
#SBATCH --mem=4000
#SBATCH --mail-type=END

module load r-env rstudio

source scripts/command_utility.sh
num_cmnds=$( cmnds_in_file )

#update sample description file  
python scripts/update_sample_description.py $samp_desc


echo "Rscript scripts/DE_exp.R $samp_desc $biomart_dataset $adj_pval_cutoff" >> commands/$num_cmnds"_DE_exp_commands.txt"
sbatch_commandlist -t 0:30:00 -mem 4000 -jobname DE_exp -threads 1 -commands commands/$num_cmnds"_DE_exp_commands.txt"

if [ ! -d "$HOME/R_libs" ]
   then
   mkdir $HOME/R_libs
   wget --directory-prefix=$HOME/ https://github.com/mikelove/tximport/archive/master.tar.gz
   R CMD INSTALL -l $HOME/R_libs/ $HOME/master.tar.gz
   rm $HOME/master.tar.gz
fi

echo "Rscript scripts/DE_exp_tximport.R $samp_desc_rsem $biomart_dataset $adj_pval_cutoff $USER" >> commands/$num_cmnds"_DE_exp_rsem_commands.txt"
sbatch_commandlist -t 0:30:00 -mem 4000 -jobname DE_exp -threads 1 -commands commands/$num_cmnds"_DE_exp_rsem_commands.txt"

mv *_out_*txt OUT
mv *_err_*txt ERROR
#Rscript scripts/DE_exp.R $samp_desc $biomart_dataset $adj_pval_cutoff

#append parameters of the run to the end of the DE file, for record-keeping purposes
