import pandas as pd
import joblib
import sys

input_f = pd.read_csv(sys.argv[1])

ensg_to_prior_inparanoid = joblib.load('ensmusg_to_DE_prior_inparanoid')
ensg_to_prior_biomart = joblib.load('ensmusg_to_DE_prior_Biomart')

l = []
for i,j in input_f.iterrows():
    if j.ensembl_gene_id in ensg_to_prior_inparanoid:
        l.append(ensg_to_prior_inparanoid[j.ensembl_gene_id])
    elif j.ensembl_gene_id in ensg_to_prior_biomart: #ONLY TAKE from biomart if couldn't find it in inparanoid
        l.append(ensg_to_prior_biomart[j.ensembl_gene_id])
    else:
        l.append('')

input_f['DE Prior'] = l

input_f.to_csv('./DE_genes_copy.csv', index=False)

###################################################



