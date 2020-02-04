#!/bin/bash -l
# author: dasroy
#SBATCH -J Star
#SBATCH -o OUT/singleStar_out_%j.txt
#SBATCH -e ERROR/singleStar_err_%j.txt
#SBATCH -p large
#SBATCH -n 1
#SBATCH -t 12:00:00
#SBATCH --mem=4000
#SBATCH --mail-type=END

source scripts/command_utility.sh

module load gcc star r-env rstudio perl

if [ ! -d rsem_indx  ]; then
	
	mkdir rsem_indx
	overhang=$(( maxReadLength - 1 ))

	echo "/users/murrayry/RSEM-1.3.1/rsem-prepare-reference --gtf $gene_annotation --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin -p 8 --star-sjdboverhang $overhang $genome_file rsem_indx/rsem_ref" >> commands/$num_cmnds"_rsem_prepare_reference".txt

	/users/murrayry/RSEM-1.3.1/rsem-prepare-reference --gtf $gene_annotation --star --star-path /appl/soft/bio/star/gcc_9.1.0/2.7.2a/bin -p 8 --star-sjdboverhang $overhang $genome_file rsem_indx/rsem_ref

	mv *_out_*txt OUT
	mv *_err_*txt ERROR

fi
#Indexing the genome this way doesn't work with RSEM
## Starting Indexing the genome
#if [ ! -d star-genome_ann_Indices ]; then
#	
#	mkdir star-genome_ann_Indices
#	overhang=$(( maxReadLength - 1 ))
#
#	echo "STAR --runMode genomeGenerate --genomeDir star-genome_ann_Indices \
#		--genomeFastaFiles $genome_file --sjdbGTFfile  $gene_annotation \
#		--runThreadN 6 --sjdbOverhang $overhang" >> commands/$num_cmnds"_star-genome_annotated".txt 
#
#	sbatch_commandlist -t 12:00:00 -mem 64000 -jobname star-indexing \
#	-threads 6  -commands commands/$num_cmnds"_star-genome_annotated".txt 
#
#	mv *_out_*txt OUT
#	mv *_err_*txt ERROR
#
#fi
## Finished Indexing the genome 


## Alignment of each fastq file starts here
  if [ ! -d "$2" ]
   then
        mkdir $2
   fi

for my_file in $1/*.{fastq,fastq.gz,fq,fq.gz}
do
  if [  -f "$my_file" ]
   then
        filename="${my_file##*/}"
        extension="${filename##*.}"
        filename="${filename%.*}"
	
	uncompress=""
	if [ "$extension" == "gz" ]
	then
		uncompress="--readFilesCommand zcat"
	fi 


  	echo "STAR --genomeDir rsem_indx --readFilesIn  $my_file $uncompress \
		--outFileNamePrefix $2/star_annotated_$filename \
		--outSAMtype BAM SortedByCoordinate --runThreadN 4" >> commands/$num_cmnds"_STAR_align_"$1_commands.txt
fi
done

sbatch_commandlist -t 12:00:00 -mem 48000 -jobname STAR_alignment_array \
-threads 4 -commands commands/$num_cmnds"_STAR_align_"$1_commands.txt

mv *_out_*txt OUT
mv *_err_*txt ERROR

source scripts/multiqc_slurm.sh $2
## Alignment of each fastq file starts here



