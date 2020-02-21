args<-commandArgs(TRUE)
#args[1] is sample_description.csv
#args[2] is whether human or mouse, hsapiens_gene_ensembl or mmusculus_gene_ensembl
#args[3] is adjusted pvalue cutoff

#user_path =paste0('/users/', args[3], '/R_libs')
#library(tximport, lib.loc=user_path)

setwd("./")

if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}
if (!requireNamespace("DESeq2", quietly = TRUE)) {
    BiocManager::install("DESeq2", version = "3.8")
}

require(DESeq2)
library(tximport)

samples <- read.csv(args[1],header = TRUE)

rownames(samples) <- samples$sampleName

files <- paste0("", samples$fileName)
names(files) <- samples$sampleName
txi.rsem <- tximport(files, type = "rsem", txIn = FALSE, txOut = FALSE)
write.csv(txi.rsem, "rsem_tpm_counts.csv")

#change genes with effective length zero to one
txi.rsem$length[txi.rsem$length == 0] <- 1
    
#ddsHTSeq <- DESeqDataSetFromHTSeqCount(sampleTable = sampleMetaData, 
#                                        directory = "./star_count/",
#                                       design= ~ pair+condition)

samples$pair <- factor(samples$pair)

ddsHTSeq<- DESeqDataSetFromTximport(txi.rsem, colData = samples, design= ~ pair+condition)
                                       ## design = ~ condition 
                                        ## will test for fold change between the two conditions (CTRL and SHH) without considering (i.e. correcting for) 'pair' information.

rlogMat<-as.data.frame(assay(rlog(ddsHTSeq)))

#######################################################
if (!requireNamespace("biomaRt", quietly = TRUE)) {
    BiocManager::install("biomaRt")
}

## Use biomart to download gene information from Ensembl
require(biomaRt)
#ensMart<-useMart("ensembl",host ="http://uswest.ensembl.org" )
# ensDataSet <- listDatasets(ensMart)
# mouse_id <- grep("mouse",ensDataSet$description,ignore.case = TRUE)
# ensDataSet[mouse_id,]

ensembl_ms_mart <- useMart(biomart="ensembl", dataset=args[2] ,host = "http://useast.ensembl.org")
## Which attributes of genes do we want to download
# grep("GC",listAttributes(ensembl_ms_mart)$description,ignore.case = TRUE)
# listAttributes(ensembl_ms_mart)[26,]
# "uniprotswissprot",  "uniprotsptrembl"
gene_attributes<- c("ensembl_gene_id",  "external_gene_name", "gene_biotype", "percentage_gene_gc_content")
suppressMessages(
  gene_attribute_data <- getBM(attributes=gene_attributes,values= rownames(rlogMat), ensembl_ms_mart, filters = "ensembl_gene_id") )
# saveRDS(gene_attribute_data,file = "gene_annotation.rds")

##########################################################

# Filtering out low expressed genes https://bioconductor.org/packages/devel/bioc/vignettes/DESeq2/inst/doc/DESeq2.html#pre-filtering
dermis <- ddsHTSeq[ rowSums(counts(ddsHTSeq)) > 1, ]

##########################################################
# Generate PCA plot

# rlog transform
rld <- rlog(ddsHTSeq)

suppressPackageStartupMessages(require(ggplot2))
pcaData <- plotPCA(rld, intgroup = c("condition","pair"),returnData=TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))
p <- ggplot(pcaData, aes(PC1, PC2,  text=name,group=pair)) +
            geom_point(size=3,aes(color=condition)) + geom_line() +
            xlab(paste0("PC1: ",percentVar[1],"% variance")) +
            ylab(paste0("PC2: ",percentVar[2],"% variance")) +
            coord_fixed() + ggtitle(" ")

png(filename="pcaplot_tpm.png")
plot(p)
dev.off()

write.csv(pcaData, "PCA_data_tpm.csv")
#############################################################

## Running DESeq
data_DESeq <- DESeq(dermis)
## Building the result table
  
res <- results(data_DESeq, contrast=c("condition", "Exp", "Ctrl"))

#resSig <- subset(res, padj < p_adjusted)
resSig <- as.data.frame(res)

## Annotated the genes with previously downloaded data
resSig$ensembl_gene_id <- rownames(resSig)
resSig_dermis_annotated <- merge(resSig,gene_attribute_data,by="ensembl_gene_id")

write.csv(resSig_dermis_annotated, "DE_genes_tpm.csv")
#resSig_dermis_annotated[,c(-1,-8,-9)] <-round(resSig_dermis_annotated[,c(-1,-8,-9)],4)
# DT::datatable(resSig_dermis_annotated[,c(1:3,6:9)],rownames = FALSE)
#resSig_dermis_annotated[,c(1:3,6:9)]
