import pandas as pd

tpm_df = pd.read_csv('./rsem_tpm_counts.csv', index_col=0)
sample_desc_df = pd.read_csv('./sample_description_for_rsem.csv')

cols = [i for i in tpm_df.columns if 'abundance' in i]

d = {ensg:{} for ensg, coldata in tpm_df.iterrows()}

for ensg, coldata in tpm_df.iterrows():
    for col in cols:
        d[ensg][col] = coldata[col]

#dict to relate tpm col names with sample_Desc sampleName field
#dict to relate sample_desc sam[pleName with condition

condition_d = {j.sampleName.replace('-', '.'):j.condition for i,j in sample_desc_df.iterrows()}

cd = {}
for i,j in sample_desc_df.iterrows():
    for col in cols:
        if j.sampleName.replace('-', '.') in col:
            cd[col] =j.sampleName.replace('-', '.')

for i,j in condition_d.items():
    print (i,j)
for i,j in cd.items():
    print (i,j)

print (cols)

fd = {}

for ensg, coldata in d.items():
    ctrl, exp = [], []
    for col in cols:
        sampleName = cd[col]
        condition = condition_d[sampleName.replace('-', '.')]
        if condition == 'Exp':
            exp.append(coldata[col])
        else:
            ctrl.append(coldata[col])
    mean_exp = sum(exp)/len(exp)
    mean_ctrl = sum(ctrl)/len(ctrl)
    fd[ensg] = [mean_exp, mean_ctrl, mean_exp - mean_ctrl]
        
mean_exp_col, mean_ctrl_col, diff = [], [], []

rmse_de_df = pd.read_csv('./DE_genes_tpm_withPriors.csv', index_col=1)
for ensg, coldata in rmse_de_df.iterrows():
    i = fd[ensg]
    mean_exp_col.append(i[0])
    mean_ctrl_col.append(i[1])
    diff.append(i[2])

rmse_de_df['Mean_exp'] = mean_exp_col
rmse_de_df['Mean_ctrl'] = mean_ctrl_col
rmse_de_df['tpm_diff'] = diff


rmse_de_df.to_csv('DE_genes_tpm_withPriors_tpm.csv')


#final: { ensg : [ctrl_mean, exp_mean, exp_mean - ctrl_mean] }
