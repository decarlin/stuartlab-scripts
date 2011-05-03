#!/usr/bin/python

##############################################################################################
# This program is a binary classifier of a table of data.
# It transforms a table of numeric values data into a table of  0 and 1s
# by finding the minimum least squares distance to the mean.
#
# Input is a tab (or specified delimeter such as a comma) seperated file
# Processing is done by rows.
# The output is the transformed file. Non numbers (such as labels) are passed though.
# Spaces between labels and numbers may not be preserved.
#
# Ted Goldstein, Baskin SOE, UCSC, 4 June 2010
##############################################################################################

import pdb
import math
import os
import sys

from copy import deepcopy

def calculateThreshold(data):
    data.sort()
    leastIndex = -1
    leastValue = 0
    k = len(data)
    for i in xrange(1, k):
      lowAvg =  float(sum(data[0:i])) / i
      highAvg = float(sum(data[i:]))  / (k - i)
      low = high = 0
      for j in xrange(0,i): low  = low  + sqr(lowAvg - data[j])
      for j in xrange(i,k): high = high + sqr(highAvg - data[j])
      total = low + high
      if leastIndex < 0 or leastValue > total:
	  leastIndex = i
	  leastValue = total
    if leastIndex == (k - 1):
       return float(data[k-1] + data[k-2] ) / 2
    else:
       return float(data[leastIndex+1] + data[leastIndex]) /2

# square
def sqr(x): return x*x


def getNumbersInList(data):
  results = []
  for x in data:
      try:
	 results.append(float(x))
      except:
         continue

  return results

def die(arg):

   sys.stderr.write("Unknown argument "+ arg)
   sys.stderr.write("""

Usage:
  dichotomizer < sourcefile > destfile

Optional arguments:
     --separator=, (can be comma or any string)
     --byColumn 
     --lowValue=number 
     --highValue=number 
     --numberOfFooterRowsToSkip=number   
     --numberOfHeaderRowsToSkip=number 
     --numberOfLeftColumnsToSkip=number 
     --numberOfRightColumnsToSkip=number 

     --outputthreshold=filename


     --samRdata= CSV .txt Experiments file to slice and dice
     --samRdir=tmpdir directory to put temporary input to SAM
     --samRresultsDir= directory to put results (one gene set per column)

Authors
     Ted Goldstein and Josh Stuart

Based on ideas from 
     Boolean implication networks derived from large scale, whole genome microarray datasets Debashis Sahoo*, David L Dill, Andrew J Gentles, Robert Tibshirani and Sylvia K Plevritis
     Genome Biol. 2008; 9(10): R157.
     Published online 2008 October 30. doi: 10.1186/gb-2008-9-10-r157.
     http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2760884/?tool=pubmed
""")
   sys.exit(1)



def processTable(lines, byColumns, maxCol, lowValue, highValue, numberOfFooterRowsToSkip, numberOfHeaderRowsToSkip, numberOfLeftColumnsToSkip, numberOfRightColumnsToSkip, outputthreshold):

    if byColumns:
       for i in xrange(numberOfLeftColumnsToSkip, maxCol - numberOfRightColumnsToSkip):
	    numbersInColumn = []
	    for j in xrange(numberOfHeaderRowsToSkip, len(lines) - numberOfFooterRowsToSkip):
	      line = lines[j]
	      if i < len(line):
	         try:
		    numbersInColumn.append(float(line[i]))
	         except:
		    continue
	    if len(numbersInColumn) > 1:
		threshold = calculateThreshold(numbersInColumn)
		if outputthreshold:
		   outputthreshold.write(str(i)+"\t"+str(threshold)+"\n")
		for j in xrange(numberOfHeaderRowsToSkip, len(lines) - numberOfFooterRowsToSkip):
		  line = lines[j]
		  if i < len(line):
		     try:
			value = float(line[i])
			if value < threshold:
			    line[i] = lowValue
			else:
			    line[i] = highValue
		     except:
			continue
	         
           
    else: # by Rows
	for j in xrange(numberOfHeaderRowsToSkip, len(lines) - numberOfFooterRowsToSkip):
	   line = lines[j]
	   numbersInLine = (getNumbersInList(line))
	   if len(numbersInLine) > 1:
	       threshold = calculateThreshold(numbersInLine)
	       if outputthreshold:
		   outputthreshold.write(str(j)+"\t"+str(threshold)+"\n")
	       for i in xrange(numberOfLeftColumnsToSkip,len(line) - numberOfRightColumnsToSkip):
	           try:
		      if float(line[i]) < threshold: 
			 line[i] = lowValue
		      else:
			 line[i] = highValue
	           except:
		      continue

def readColumnFile(input, separator, doLn, logBase):
    lenColumns = 0
    lines = []
    numberCount = 0
    nonNumberCount = 0

    for line in input:
       line = line[:-1]
       lineAsColumns = line.split(separator)
       n = len(lineAsColumns)
       if lenColumns < n: 
	   lenColumns = n

       for i in xrange(0, n):
	   try:
	      value = float(lineAsColumns[i])
	      if doLn and value > 0:
		  value = math.log(value)
	      elif logBase and value > 0:
		  value = math.log(value, logBase)

	      lineAsColumns[i] = value
	      numberCount = numberCount + 1 
	   except Exception, err:
	      nonNumberCount = nonNumberCount + 1 
       lines.append(lineAsColumns)
    return lines, lenColumns , numberCount , nonNumberCount 

def main(argv):
    # initialize arguments
    lowValue  = "0"
    highValue = "1"
    separator = "\t"
    howManyNumbers = 0
    byColumns = False
    numberOfHeaderRowsToSkip = 0
    numberOfFooterRowsToSkip = 0
    numberOfLeftColumnsToSkip = 0
    numberOfRightColumnsToSkip = 0
    input = sys.stdin
    output = sys.stdout
    MeVdir = None
    samRresultsDir = None
    samRdata = None
    samRdir = None
    doLn = False
    logBase = 0
    outputthreshold = None

    # process arguments
    for arg in argv[1:]:
	try:
	    if arg.startswith("--ln"): doLn = True
	    elif arg.startswith("--log="): logBase = float(arg.split("=")[1])
	    elif arg.startswith("--input="): input = open(arg.split("=")[1], "r")
	    elif arg.startswith("--output="): output = open(arg.split("=")[1], "w")
	    elif arg.startswith("--outputthreshold="): outputthreshold = open(arg.split("=")[1], "w")
	    elif arg.startswith("--MeVdir="): MeVdir = arg.split("=")[1]
	    elif arg.startswith("--samRdir="): samRdir = arg.split("=")[1]
	    elif arg.startswith("--samRdata="): samRdata = arg.split("=")[1]
	    elif arg.startswith("--samRresultsDir="): samRresultsDir = arg.split("=")[1]

	    elif arg.startswith("--separator="): separator = arg.split("=")[1]
	    elif arg.startswith("--byColumn"): byColumns = True

	    elif arg.startswith("--numberOfFooterRowsToSkip="): 
		 numberOfFooterRowsToSkip = int(arg.split("=")[1])
	    elif arg.startswith("--numberOfHeaderRowsToSkip="): 
		 numberOfHeaderRowsToSkip = int(arg.split("=")[1])
	    elif arg.startswith("--numberOfLeftColumnsToSkip="): 
		 numberOfLeftColumnsToSkip = int(arg.split("=")[1])
	    elif arg.startswith("--numberOfRightColumnsToSkip="): 
		 numberOfRightColumnsToSkip = int(arg.split("=")[1])

	    elif arg.startswith("--lowValue="): lowValue = float(arg.split("=")[1])
	    elif arg.startswith("--highValue="): highValue = float(arg.split("=")[1])
	    elif arg.startswith("--help"): die()
	    else: die(arg) 
	except:
	    die(arg) 

    # initialize working variables

    # read it in
    (lines, lenColumns , numberCount , nonNumberCount) = readColumnFile(input, separator, doLn, logBase)

    # work it over
    processTable(lines, byColumns, lenColumns, lowValue, highValue, numberOfFooterRowsToSkip, numberOfHeaderRowsToSkip, numberOfLeftColumnsToSkip, numberOfRightColumnsToSkip, outputthreshold)


    if samRdata != None:
	baseNames=samRgroupOutput(lines, samRdata, samRdir, samRresultsDir)
    elif MeVdir != None:
	MeVgroupOutput(lines, MeVdir)
    else:
	simpleOutput(lines, output,separator)


def simpleOutput(lines, output, separator):
    # write it out
    for line in lines:
       if len(line) == 1:
       	   output.write(str(line[0]))
	   output.write("\n")
       else:
	   for i in xrange(0,len(line)):
	       if i > 0:
		   output.write(separator)
	       output.write(str(line[i]))
	   output.write("\n")

hitList = [ None, "184A1N4", "184B5", "600MPE", "AU565", "BT20", "BT474", "BT483", "CAMA1", "HCC38", "HCC70", "HCC202", "HCC1143", "HCC1187", "HCC1395", "HCC1419", "HCC1428", "HCC1500", "HCC1569", "HCC1599", "HCC1806", "HCC1937", "HCC1954", "HCC2185", "HCC2218", "HCC3153", "HS578T", "LY2", "MCF12A", "MCF10F", "MCF7", "MDAMB134VI", "MDAMB157", "MDAMB175VII", "MDAMB231", "MDAMB361", "MDAMB415", "MDAMB436", "MDAMB453", "MDAMB468", "SKBR3", "SUM44PE", "SUM52PE", "SUM102PT", "SUM149PT", "SUM159PT", "SUM185PE", "SUM225CWN", "SUM1315MO2", "T47D", "UACC812", "UACC893", "ZR751", "ZR7530", "ZR75B", "BT549", "MCF10A" ]

def MeVgroupOutput(lines, directory):
    drugNames = lines[0]
    lenDrugNames = len(drugNames)
    lenGenes = len(lines)
    for drug_i in xrange(1,lenDrugNames):

       #load the gene map
       geneMap = {}
       for gene_i in xrange(1, lenGenes):
	   geneName = lines[gene_i][0].upper()
           value = lines[gene_i][drug_i]
	   if value == "0":
	       group = "1"
	   else:
	       group = "2"
	   geneMap[geneName] = group

       output = open(directory+"/"+drugNames[drug_i], "w")
       output.write("""# Assignment File
# User: tedgoldstein Save Date: Mon Jun 28 17:45:05 PDT 2010
#
Module:	SAM: Two-Class Unpaired
Group 1 Label:	1
Group 2 Label:	2
#
Sample Index	Sample Name	Group Assignment
""")
       for lineNumber in xrange(1, len(hitList)):
	    geneName = hitList[lineNumber]
	    if geneName in geneMap:
		group = geneMap[geneName]
		output.write(str(lineNumber)+"\t"+geneName+"\t"+group+"\n")
	    else:
		output.write(str(lineNumber)+"\t"+hitList[lineNumber]+"\tExclude\n");
       output.close()


def getcolumn(table, n):
    c = [];
    for line in table:
        c.append(line[n]) 
    return c
       


def samRgroupOutput(groups, samRdata, samRdir, samRresultsDir):

    for cell_i in xrange(1, len(groups)):
	  groups[cell_i][0] = groups[cell_i][0].upper()

    cellNamesInGroups = getcolumn(groups, 0)
    del cellNamesInGroups[0]
    cellNamesInGroups = set(cellNamesInGroups)

    (data, lenDataColumns , numberDataCount , nonNumberDataCount) = readColumnFile(open(samRdata, "r"), None, True, None)
    for cell_i in xrange(1, len(data[0])):
        data[0][cell_i] = data[0][cell_i].upper()

    cellNamesInData = data[0]
    del cellNamesInData[0]
    cellNamesInData = set( cellNamesInData  )

    print "Names only in data", cellNamesInData - cellNamesInGroups
    print "Names only in group", cellNamesInGroups - cellNamesInData

    cellNames  = cellNamesInGroups & cellNamesInData


    drugNamesInGroups = groups[0]
    del drugNamesInGroups[0]
    print "DrugNames", drugNamesInGroups

    maxAllDrugs = len(groups[0])
    maxAllCellLines = len(groups)


    allDrugs = {}
    for drug_i in xrange(1, maxAllDrugs):
	drug = groups[0][drug_i]
	print "working on ", drug
	thisDrug = {}
	allDrugs[drug] = thisDrug
	for cell_i in xrange(1,maxAllCellLines):
	    value = groups[cell_i][drug_i]
	    if value == "0" or value == "1":
		 cellName = groups[cell_i][0].upper()
	         thisDrug[cellName] = value

	fn = samRdir+"/"+drug + ".sam"
	rn = samRdir+"/"+drug + ".report"
	output = open(fn, "w")
	report = open(rn, "w")
	report.write("Drug "+drug + "\n");

	for cell_i in xrange(1, len(data[0])):
	     cellName = data[0][cell_i]
	     if cellName in thisDrug:
		output.write( "\t"+thisDrug[cellName])
		report.write(" cell "+cellName + "\t"+thisDrug[cellName] +"\n");
	output.write( "\n")
	for line in data[1:]:
	    geneName = line[0]
	    output.write(geneName)
	    for cell_i in xrange(1, len(data[0])):
		 cellName = data[0][cell_i]
		 if cellName in thisDrug:
		    output.write( "\t"+str(line[cell_i]))
	    output.write( "\n")
	output.close()
	report.close()
	if samRresultsDir:
	    samRrun(fn, samRdir, samRresultsDir)
	         
def samRrun(fn, samRdir, samRresultsDir):
    t = fn.strip(samRdir).rstrip("sam")
    out = samRresultsDir + t + "samResults"
    cmd =  "/projects/sysbio/lab_apps/R_shell/sam.R " + fn + " > " + out
    print cmd
    os.system(cmd)

main(sys.argv)

