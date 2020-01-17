'''
reads sample description file, and updates file names to be the actual ones used in the star_count dir
then overwrites original file
'''

import csv
import sys
import os

fname = sys.argv[1]

star_count_files = os.listdir('./star_count/')

new_csv = []
with open(fname, 'r') as infile:
    csv_reader = csv.DictReader(infile, delimiter=',')
    
    for row in csv_reader:
        fn = row['fileName'].split('.')[0]
        for i in star_count_files:
            if fn in i:
                nfn = i
        row['fileName'] = nfn
        new_csv.append(row)

csv_file = fname
col_names = ['sampleName', 'fileName', 'pair', 'condition']

try:
    with open(csv_file, 'w') as csvfile:
        csvfile.write(','.join(col_names) + '\n')
        writer = csv.DictWriter(csvfile, fieldnames=col_names)
        for data in new_csv:
            writer.writerow(data)
except IOError:
    print("I/O error")
