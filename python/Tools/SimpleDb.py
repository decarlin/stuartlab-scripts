#! /usr/bin/env python

class DataStore():
    """An agnostic data storage unit that holds and queries all data points, by all indices.
    
    """
    def __init__(self,Training_Set_Lines,Test_Set_Lines,Patient_Status_Lines):
        """Assumes no headers are included.  Assumes column 0 is the gene names for both training and testing data.

        Each data value is stored in a "record" that is a dictionary who's keys include all the indices I could think of for this data set.  That is:
        RECORDS = {'UniqueProbeID':UniqueProbeID,'Patient_ID':Patient_ID,'Status':Status,'DataSet':DataSet,'Value':Value.strip()}
        Each Index Type E.G. Patient ID is stored in a dictionary with an obvious name E.G. self.PatientDict, these dictionaries values are lists of RECORDS where each list corresponds to all the RECORDS that are relevant to a given index.  That is if I want all RECORDS relating to patient 23 I look in self.PatientDict['23'], if I want all RECORDS relating to probe 1013 I look in self.ProbeDict['1013']. If I want all records of the training class I look in self.TrainvsTestDict['TRAIN']. 
        """
        Training_Set_Lines.sort()# Since there are the same number of lines in both files I presume that this ordering is safe for purposes of assigning the same unique probe id to both sets.  Okay, _FINE_ I'll check...  yup, they're the same.
        Test_Set_Lines.sort()# And now they're in the same order.
        self.PatientDict = {}
        self.ProbeDict = {}
        self.StatusDict = {}
        self.TrainvsTestDict = {}
        self.ProbeNametoNumberDict = {}
        self.ProbeNumbertoNameDict = {}
        TempStatus = {}
        """This mapping is used to take patient --> status data from a file and populate RECORDS with the correct mapping data."""
        for line in Patient_Status_Lines:
            sline = line.split()
            TempStatus[sline[0].strip()] = sline[1].strip()

        for UniqueProbeID, line in enumerate(Training_Set_Lines):
            """This loop consumes data line by line from the training_set.tab derived line list, parses the lines and populates the various dictionaries in the class."""
            DataSet = 'TRAIN'
            UniqueProbeID = str(UniqueProbeID + 1)
            line = line.strip()
            sline = line.split('\t')
            ProbeName = sline[0].strip()
            self.ProbeNametoNumberDict[ProbeName] = UniqueProbeID
            self.ProbeNumbertoNameDict[UniqueProbeID] = ProbeName
            datavals = sline[1:]
            for Index,Value in enumerate(datavals):
                Patient_ID = str(Index + 1)
                Status = TempStatus[Patient_ID]
                temp_dict = {'UniqueProbeID':UniqueProbeID,'Patient_ID':Patient_ID,'Status':Status,'DataSet':DataSet,'Value':Value.strip()}

                if self.PatientDict.has_key(Patient_ID):
                    self.PatientDict[Patient_ID].append(temp_dict)
                else:
                    self.PatientDict[Patient_ID] = [temp_dict]

                if self.ProbeDict.has_key(UniqueProbeID):
                    self.ProbeDict[UniqueProbeID].append(temp_dict)
                else:
                    self.ProbeDict[UniqueProbeID] = [temp_dict]

                if self.StatusDict.has_key(Status):
                    self.StatusDict[Status].append(temp_dict)
                else:
                    self.StatusDict[Status] = [temp_dict]

                if self.TrainvsTestDict.has_key(DataSet):
                    self.TrainvsTestDict[DataSet].append(temp_dict)
                else:
                    self.TrainvsTestDict[DataSet] = [temp_dict]

        for UniqueProbeID, line in enumerate(Test_Set_Lines):
            """Like the above for loop but for the testing_set.tab file.  This loop must come after the above loop."""
            DataSet = 'TEST'
            UniqueProbeID = str(UniqueProbeID + 1)
            line = line.strip()
            sline = line.split('\t')
            ProbeName = sline[0].strip()
            datavals = sline[1:]
            for Index,Value in enumerate(datavals):
                Patient_ID = str(Index + 78)
                Status = TempStatus[Patient_ID]
                temp_dict = {'UniqueProbeID':UniqueProbeID,'Patient_ID':Patient_ID,'Status':Status,'DataSet':DataSet,'Value':Value.strip()}

                if self.PatientDict.has_key(Patient_ID):
                    self.PatientDict[Patient_ID].append(temp_dict)
                else:
                    self.PatientDict[Patient_ID] = [temp_dict]

                if self.ProbeDict.has_key(UniqueProbeID):
                    self.ProbeDict[UniqueProbeID].append(temp_dict)
                else:
                    import sys
                    print "UH-OH BIG TROUBLE."
                    print "UniqueProbeID: %s"%UniqueProbeID
                    sys.exit(89)
                    self.ProbeDict[UniqueProbeID] = [temp_dict]

                if self.StatusDict.has_key(Status):
                    self.StatusDict[Status].append(temp_dict)
                else:
                    self.StatusDict[Status] = [temp_dict]

                if self.TrainvsTestDict.has_key(DataSet):
                    self.TrainvsTestDict[DataSet].append(temp_dict)
                else:
                    self.TrainvsTestDict[DataSet] = [temp_dict]

    def OutputSVMLightFormat(self,ProbeNames=None,DataSet='TRAIN'):
        """This method takes advantage of the "DataSet" index to distinguish which values should be incorporated in the SVMLight formatted output.  It takes an optional second argument which should be a dictionary of probe names.  Only records whose "UniqueProbeID" is in the ProbeName Dict will be included in the output."""
        OutList = []
        if ProbeNames == None:
            for Patient,DictList in self.PatientDict.iteritems():
                if DictList[0]['DataSet'] != DataSet:
                    """Skip irrelevant dataset(s)"""
                    continue
                if DictList[0]['Status'] == '0':
                    OutLine = '-1 '
                elif DictList[0]['Status'] == '1':
                    OutLine = '1 '

                for Dict in DictList:
                    if 'NaN' not in Dict['Value']:
                        OutLine = OutLine + str(Dict['UniqueProbeID'])+':'+str(Dict['Value'])+' '
                OutList.append(OutLine)
        else:
            for Patient,DictList in self.PatientDict.iteritems():
                if DictList[0]['DataSet'] != DataSet:
                    """Skip irrelevant dataset(s)"""
                    continue
                if DictList[0]['Status'] == '0':
                    OutLine = '-1 '
                elif DictList[0]['Status'] == '1':
                    OutLine = '1 '

                for Dict in DictList:
                    if 'NaN' not in Dict['Value']:
                        if self.ProbeNumbertoNameDict[Dict['UniqueProbeID']] in ProbeNames:     
                            OutLine = OutLine + str(Dict['UniqueProbeID'])+':'+str(Dict['Value'])+' '
                OutList.append(OutLine)





        return OutList

    def SnarfAppendSVMAlphas(self,AlphaList):
        AlphaMap = dict([kvtup for kvtup in AlphaList])
        for Probe, RecordList in self.ProbeDict.iteritems():
            for Record in RecordList:
                if AlphaMap.has_key(Record['Patient_ID']):
                    Record['Alpha'] = AlphaMap[Record['Patient_ID']]

    def CalculateProbeInformativeness(self,Probes=None):
        if Probes == None:
            Probes = self.ProbeDict.keys()

        InformativenessList = []
        for Probe in Probes:
            DeltaTotal = 0.0
            Numerator = 0.0
            RecordList = self.ProbeDict[Probe]
            for Record in RecordList:
                if Record['DataSet'] == 'TRAIN':
                    if 'NaN' in Record['Value'] or not Record.has_key('Alpha'):
                        continue
                    DeltaTotal+=1.0
                    if Record['Status'] == '0':
                        NumeratorTerm = Record['Alpha'] * float(Record['Value']) * -1.0
                    elif Record['Status'] == '1':
                        NumeratorTerm = Record['Alpha'] * float(Record['Value']) 
                Numerator = Numerator + NumeratorTerm
            Informativeness = (Numerator / DeltaTotal)
            InformativenessList.append((self.ProbeNumbertoNameDict[Probe],Informativeness))

        InformativenessList.sort(key=lambda x:x[1])
        return InformativenessList

    
def main():
    """This main function (called below which the script is launched from the command line) generates the required SVMlight formatted files.  This script expects to be passed command line options something like this: 
        
        SimpleDb.py --train=training_set.tab --test=testing_set.tab  --pats=patient_data.tab  --tops=top100absfisher
        
        The fourth file 'top100absfisher' is generated by the 'calculate_fisher_criterion' function in 'fisher_criterion.py' with the 'ABS' parameter set to true.  Clearly there are cleaner ways to do this... but...  I was in a hurry.  Next time around I'll make calculate_fisher_criterion a method of DataStore, I didn't do this originally because DataStore didn't exist, when I originally wrote calculate_fisher_criterion. """
    import optparse
    parser = optparse.OptionParser()
    parser.add_option("--test")
    parser.add_option("--train")
    parser.add_option("--pats")
    parser.add_option("--tops")
    (options,args) = parser.parse_args()
    Top100FishAbsolute = dict([(line.strip(),'') for line in open(options.tops)])
    TrainWithHeader = [line for line in open(options.train)]
    TrainingData = TrainWithHeader[1:]
    TestWithHeader = [line for line in open(options.test)]
    TestingData = TestWithHeader[1:]
    PatientStatusDataWithHeader = [line for line in open(options.pats)]
    PatientStatusData = PatientStatusDataWithHeader[1:]
    ExperimentalData = DataStore(TrainingData,TestingData,PatientStatusData)

    """Above is reading data in, below is outputting data."""
    FullTrainFile = open('train_4919.svm','w')
    FullTrainLines = ExperimentalData.OutputSVMLightFormat(DataSet='TRAIN')
    for line in FullTrainLines:
        FullTrainFile.write(line+'\n')
    FullTrainFile.close()

    FullTestFile = open('test_4919.svm','w')
    FullTestLines = ExperimentalData.OutputSVMLightFormat(DataSet='TEST')
    for line in FullTestLines:
        FullTestFile.write(line+'\n')
    FullTestFile.close()

    TopTestFile = open('test_100.svm','w')
    TopTestLines = ExperimentalData.OutputSVMLightFormat(Top100FishAbsolute,DataSet='TEST')
    for line in TopTestLines:
        TopTestFile.write(line+'\n')
    TopTestFile.close()

    TopTrainFile = open('train_100.svm','w')
    TopTrainLines = ExperimentalData.OutputSVMLightFormat(Top100FishAbsolute,DataSet='TRAIN')
    for line in TopTrainLines:
        TopTrainFile.write(line+'\n')
    TopTrainFile.close()

if __name__ == '__main__':
    main()
