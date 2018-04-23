# 4-RNA-seq
A [slurm](https://slurm.schedmd.com/) based schema for RNA-seq analysis to execute on linux clusters.

The purpose of this project to develop a easily customizable commandline based schema. Additionally it has basic linux scripts for file manipulation which is key to execute command line pipeline.

## Installation
__Download__   
		*wget https://github.com/vondoRishi/4-RNA-seq/archive/master.zip*  
		mkdir target_directory  
		unzip 4-RNA-seq-master.zip -d target_directory

![The schema](https://github.com/vondoRishi/4-RNA-seq/blob/master/4-rna-seq.jpg)

# RNA-seq pipeline

This pipeline and workflow is based on [Taito.csc server batch scripts](https://research.csc.fi/taito-batch-jobs). The objective of this documentation is to make execution faster and reproducible as much as possible. The project folder ( should be in $WRKDIR path) should contain these folders before starting
* scripts : contains all scripts to run in taito server
* OUT : contains  output files from all scripts 
* ERROR : contains error files from all scripts 
* commands : contains actual commands { will be required in future to find the project specific parameters }
* rawReads : should contain sequencing reads generated by the sequencing machine. Folder name could be anything.

**Additional info** :  Library type, sequencing platform
Input: Reference Genome (DNA sequences) fasta and annotation file (GTF)
Run “ls -lrth” after every step to find the last modified file
## Dependency   
Need to install afterqc by the user.
* [Multiqc](http://multiqc.info/) ( run almost after all the commands) { installation [guide](https://github.com/vondoRishi/4-RNA-seq/blob/master/Multiqc%20install.md)}   
* [AfterQC](https://github.com/OpenGene/AfterQC)  { installation [guide](https://github.com/vondoRishi/4-RNA-seq/blob/master/AfterQC%20install.md) .}

## QC and Filtering
1.	Start QC with [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)  
Input : directory rawReads with fastq or fastq.gz files  
execution : “sbatch -D $PWD --mail-user ur_email_at_domain scripts/fastqc.sh rawReads”  
Output : directory rawReads  

2. Filter/trimminging with  
     a) [AfterQC](https://github.com/OpenGene/AfterQC)  
Execution : sbatch -D $PWD --mail-user ur_email_at_domain scripts/afterqc_batch.sh rawReads  
Output : directory good, bad and QC  
     b) AfterQC can not trim adapters from [single end reads](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-017-1469-3). Hence Trimmomatic to cut adapters \[ check for trimming parameters ] \[ Tips for filename ]  
		Input : directory good with fastq or fastq.gz files   
		execution : sbatch -D $PWD --mail-user ur_email_at_domain scripts/trimmo.sh good trimmed_reads  
		Output : directory trimmed_reads  

{ Run step 1 review effect of trimming }

3. [Sortmerna.sh](http://bioinfo.lifl.fr/RNA/sortmerna/) \[ We can also execute this at the very beginning (optional) ]  
	Sometimes ribosomal or any other unwanted RNAs may present in the library. Sortmerna could be used to filterout them.  
	Input: good   
	Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/sortmerna.sh trimmed_reads sortMeRna   
	Output: sortMeRna  
	Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/fastqc.sh sortMeRna  
	Output: sortMeRna  

 ## Alignment 
 Depending upon the library preparation kit the parameters of alignment software need to set. 
 Below is few example of different popular library kit. \[ please report any missing library type and parameters]    
### **Unstranded:**
Information regarding the strand is not conserved (it is lost during the amplification of the mRNA fragments).  
**Kits:** TruSeq RNA Sample Prep kit  
**Parameters:**  
* TopHat / Cufflinks / Cuffdiff: library-type fr-unstranded  
*  HTSeq: stranded -- no  
### **Directional, first strand:**
The second read (read 2) is from the original RNA strand/template, first read (read 1) is from the opposite strand. The information of the strand is preserved as the original RNA strand is degradated due to the dUTPs incorporated in the second synthesis step.  
**Kits:**  
* All dUTP methods, NSR, NNSR  
* TruSeq Stranded Total RNA Sample Prep Kit  
* TruSeq Stranded mRNA Sample Prep Kit  
* NEB Ultra Directional RNA Library Prep Kit   
* Agilent SureSelect Strand-Specific  
  
**Parameters:**  
* TopHat / Cufflinks / Cuffdiff: library-type fr-firststrand  
* HTSeq: stranded -- reverse  
### **Directional, second strand:**
The first read (read 1) is from the original RNA strand/template, second read (read 2) is from the opposite strand. The directionality is preserved, as different adapters are ligated to different ends of the fragment.   
**Kits:**  
* Directional Illumina (Ligation), Standard SOLiD  
* ScriptSeq v2 RNA-Seq Library Preparation Kit  
* SMARTer Stranded Total RNA   
* Encore Complete RNA-Seq Library Systems  
* Ovation® SoLo RNA-Seq Systems \[ checked through IGV tools ]
  
**Parameters:**  
* TopHat / Cufflinks / Cuffdiff: library-type fr-secondstrand  
*  HTSeq: stranded -- yes  
Source : [Directional RNA-seq data -which parameters to choose?](http://chipster.csc.fi/manual/library-type-summary.html)

To align to a reference genome 
* __Star:__  
  Set the parameter --sjdbOverhang (## sjdbOverhang should be (Max_Read_length - 1). Additionally set path to reference genome and gtf files.  
  Input: good  ( set the path to reference genome and gtf files)  
  Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/star-genome_annotated.sh good star_output   
  Output: star_output (contains bam files and quality report star_output.html)
	
	OR

* __Tophat2:__ run \[ change your parameters for stranded ]  
	Set path to reference genome in the script.
  Input: good  
  Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/tophat2.sh good tophat2_output   
  Output: tophat2_output (contains bam files and quality report tophat2_output.html)  
  
 ## Counting
Stranded?? Set the parameter
\[ STAR can also give count values of htseq-count’s default parameter ]   
For Star output
  + Set path to GTF file  
  Input: star_output   
  Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/star_htseq-count.sh star_output   
  Output: star_output/htseq_*txt   
  
Or Tophat output   
  + Set path to GTF file  
  Input: tophat2_output   
  Execution: sbatch -D $PWD --mail-user ur_email_at_domain scripts/tophat2_htseq-count.sh tophat2_output
  Output: tophat2_output/htseq_*txt


# EXTRA

## Alignment read viewer
Need to sort (uncomment for tophat output bams) and index.
* sbatch -D $PWD --mail-user ur_email_at_domain scripts/samtools_index.sh bam_directory

## Compressing fastq files
* sbatch -D $PWD --mail-user ur_email_at_domain scripts/compress_fastq.sh old_data

## Cufflink 
* sbatch scripts/cuffdiff_batch.sh Derm Ctrl Fgf20 star-genome_annotated 
