#!/bin/bash -l
# created: June 4, 2019
# author: murrayry
#SBATCH -J overview
#SBATCH -o OUT/slurmJob_%j.txt
#SBATCH -e ERROR/slurmJob_%j.txt
#SBATCH -p large
#SBATCH -n 1
#SBATCH -t 19:50:00
#SBATCH --mem-per-cpu=8000
#SBATCH --mail-type=END
#SBATCH --account=dasroy

wait_for_job () {
	#while the number of lines in the squeue is > 2, WAIT
	while (( "$(squeue -u $USER | wc -l)" > 2 )); do :; done 
}

sed -i '/#SBATCH --mail-type=END/a #SBATCH --account=dasroy' $PWD/scripts/*.sh
sed -i '/#SBATCH --mail-type=END/a #SBATCH --mail-user=ryan.z.murray@helsinki.fi' $PWD/scripts/*.sh

num_files=$(ls $PWD/$1/*{fastq,fastq.gz,fq,fq.gz} | wc -l)
sed -i "/#SBATCH --mail-type=END/a #SBATCH --array=1-$num_files" $PWD/scripts/rsem_array_cmnd.sh

sbatch scripts/fastqc.sh $1
wait_for_job
sleep 25s

sbatch scripts/afterqc_batch.sh $1
wait_for_job

sbatch scripts/trimmo.sh good trimmed_reads
wait_for_job

sbatch scripts/sortmerna.sh trimmed_reads sortMeRna
wait_for_job

rm -f sortMeRna/rRna*.fq

sbatch scripts/compress_fastq.sh sortMeRna
wait_for_job

sbatch scripts/fastqc.sh sortMeRna
wait_for_job
sleep 25s

#python -c "import re; regex = re.compile('(\d{1,3}) bp'); res = regex.findall(open('./sortMeRna/sortMeRna.html', 'r').read()); m = max([int(i) for i in res]); print m"
python -c "import re; regex = re.compile('(\d{1,3}) bp'); res = regex.findall(open('./sortMeRna/sortMeRna.html', 'r').read()); m = max([int(i) for i in res]); f = open('4-rna-seq.config', 'a'); f.write('maxReadLength=' + str(m)); f.close()"

sbatch scripts/rsem_genome_check.sh
wait_for_job

sbatch scripts/rsem_array_cmnd.sh sortMeRna rsem_counts
wait_for_job

sbatch scripts/star.sh sortMeRna star_alignment
wait_for_job

sbatch scripts/star_htseq-count.sh star_alignment star_count
wait_for_job
sleep 25s

sbatch scripts/multiqc_slurm.sh
wait_for_job

sbatch scripts/diff_exp.sh
wait_for_job
sleep 25s

module load python-data
python scripts/add_prior.py DE_genes.csv

source scripts/multiqc_slurm.sh
# This script will print some usage statistics to the
# end of file: fastqc_out
# Use that to improve your resource request estimate
# on later jobs.
used_slurm_resources.bash

