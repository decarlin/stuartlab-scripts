#!/usr/bin/python

import csv
from operator import itemgetter

files = "/projects/sysbio/users/penfold/runs/GeneLevel/SMO/PolyKernel_1_0_BestFirst-5/results_"+"%i"+".txt"

# read all rows inlcuding weightings from results_x.txt files:
list1=[]
for j in range (6):
   if j > 0:
      y = files %j
      for lines in csv.reader(open(y).readlines()[14:-46], delimiter=' '):
          list1.append(lines)
# print len (list1)

#obtain the gene names from column -1:
gene_names=[]
gene_sort =[]
for i in list1:
   gene_names.append(i[-1])
   gene_sort.append(int(i[-1]))

#the set command identifies all the unique entries
genes_sorted_entrez_no = sorted(list(set(gene_sort )))
genes_sorted_names     = sorted(list(set(gene_names)))
#print genes_sorted_names
#print len(genes_sorted_names)

#creates a list with the geneID and weight
genes_and_weights =[]
for i in list1:
      if   i[-4] != '':
         genes_and_weights.append (i[-1])
         genes_and_weights.append (float(i[-4 ]))
      elif i[-4] =='':
         if i[-5] != '':
           genes_and_weights.append (i[-1])
           genes_and_weights.append (float(i[-5 ]))
         elif i[-5] == '':
          if i[-6] != '':
            genes_and_weights.append (i[-1])
            genes_and_weights.append (float(i[-6 ]))
          elif i[-9] != '':
		genes_and_weights.append (i[-1])
		genes_and_weights.append (int(i[-9]))
      
#creates a nested list, each list containing all the weights
#where no weights appear a '0' is inputted
collated_weights = []
for j in genes_sorted_names:
    temp1=[]
    temp1.append(j)
    for k in range(len(genes_and_weights)):
       if j == genes_and_weights[k]:
         temp1.append (genes_and_weights[k+1])
    while len(temp1) < 6:
           temp1.append (0)
    collated_weights.append(temp1)

#finding the average weighting
average_weight_by_ID=[]
for i in collated_weights:
    i.append((sum(i[1:-1]))/5)
    temp=[]
    if i[-1]!=0:
       temp.append(i[0])
       temp.append(i[-1])
       temp.append(abs(i[-1]))
       average_weight_by_ID.append(temp)

#creating a gene list which excludes any genes without weightings
average_weight_by_weight=(sorted(average_weight_by_ID, key=itemgetter(-1), reverse=True))
compiled_gene_list=[]
for i in average_weight_by_ID:
    compiled_gene_list.append(i[0])
print compiled_gene_list

#writing lists to files
writer = csv.writer(open('compiled_gene_list.txt', 'wb'))
writer.writerows([compiled_gene_list])

writer = csv.writer(open('compiled_all_weights_and_average.txt', 'wb'))
writer.writerows(collated_weights)

writer = csv.writer(open('compiled_by_ID.txt', 'wb'))
writer.writerows(average_weight_by_ID)

writer = csv.writer(open('compiled_by_weight.txt', 'wb'))
writer.writerows(average_weight_by_weight)
