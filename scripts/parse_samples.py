import sys 
import os
import re
import csv
import argparse

'''
build a sample_description file for differential expression analysis
USAGE
    <directory with fastq.gz files> <pair regex> <exlusion text, commas-sep>
'''

ctrlre = re.compile('[Cc][Oo]?[Nn]?[Tt][Rr][Oo]?[Ll]?')

parser = argparse.ArgumentParser(description='Description of your program')
parser.add_argument('-d','--data', help='Directory containing processed sequences', required=True)
parser.add_argument('-p','--pairpattern', help='Regular expression pattern in file names to match paired samples. Use "_" for variable containing pair information', required=False)
parser.add_argument('-e','--exclusiontext', help='Exclude files containing text (comma-separated, no spaces).', required=False)
parser.add_argument('-n','--filename', help='Output CSV filename prefix', required=True)
parser.add_argument('--rsem', dest='rsem', action='store_true', help='Look for RSEM output files', required=False, default=False)
parser.add_argument('--switch', dest='switch', action='store_true', help='Prepare sample description file for IsoformSwitchAnalyzeR', required=False, default=False)


args = vars(parser.parse_args())

fastqdir = args['data']

if args['pairpattern'] != None:
    pairre = re.compile(args['pairpattern'].replace('_', '(\S{1})'))

all_files = os.listdir(fastqdir)
if args['rsem'] == True:
    all_files = [fastqdir + '/' + i for i in all_files if (('genes' in i) and (i != '.genes.results'))]
elif args['switch'] == True:
    all_files = [fastqdir + '/' + i for i in all_files if (('isoform' in i))]
else:
    all_files = [i for i in all_files if ('fastq.gz' == i[-8:] or 'fq.gz' == i[-5:]) ]

files = []

exclusion_text = args['exclusiontext']

if exclusion_text != None:
    exclusion_list = [i for i in exclusion_text.split(',')]
    for f in all_files:
        intext = False
        for word in exclusion_list:
            if word in f:
                intext = True
        if intext == False:
            files.append(f)
else:
    files = all_files

paird = {} # {file name : pair ID}
for f in files:
    if args['pairpattern'] != None:
        pairid = pairre.findall(f)[0]
    else:
        pairid = 'x'
    paird[f] = pairid

ctrl_files = [i for i in files if ctrlre.search(i) != None]
exp_files = [i for i in files if ctrlre.search(i) == None]

col_names = ['sampleName', 'fileName', 'pair', 'condition']

data = []

for f in ctrl_files:
    if args['switch'] == True:
        nodir = f.split('/')[1]
        sampname = '.'.join(nodir.split('.')[:-2])
    else: 
        if '/' in f:
            sampname = f.split('/')[1].split('.')[0]
        else:
            sampname = f.split(',')[0]
    
    td = {'sampleName':sampname,
          'fileName':f,
          'pair':paird[f],
          'condition':'Ctrl'}
    data.append(td)

for f in exp_files:
    if args['switch'] == True:
        nodir = f.split('/')[1]
        sampname = '.'.join(nodir.split('.')[:-2])
    else: 
        if '/' in f:
            sampname = f.split('/')[1].split('.')[0]
        else:
            sampname = f.split(',')[0]

    td = {'sampleName':sampname,
          'fileName':f,
          'pair':paird[f],
          'condition':'Exp'}
    data.append(td)

csv_file =args['filename'] + '.csv'

try:
    with open(csv_file, 'w') as csvfile:
        csvfile.write(','.join(col_names) + '\n')
        writer = csv.DictWriter(csvfile, fieldnames=col_names)
        for data in data:
            writer.writerow(data)
except IOError:
    print("I/O error")

