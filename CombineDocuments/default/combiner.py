'''
Created on Oct 30, 2018

@author: terry
'''
from asyncore import write
'''
Created on Oct 26, 2018

@author: terry
'''
#imports
import re
import os
import nltk
import time

#froms
from datetime import timedelta
from stop_words import get_stop_words
en_stop = get_stop_words('en') # list of stopwords/english

#overall runtime start
start_time = time.monotonic()

#===============================================================================
# Document Reading/Writing
#===============================================================================
def oneBigFileOutput(files, ofname):
    big_document = open(ofname, 'w+',encoding='utf-8')    
    for index,file in enumerate(files):
        logs = file.split('/')
        if(os.stat(file).st_size!=0):#only for files with content
            if (index % 2000 ==0): print('Processing:: %s' %logs[len(logs)-1])
            with open(file, 'r', encoding='utf-8') as fin:
                for line in fin.readlines():
                    big_document.write(line)
            big_document.write('\n')
        else:
            print('Empty File:: %s' %logs[len(logs)-1])#if file is empty skip it
            pass   
    big_document.close()   
#creates one file with each line being a document in the files list

#===============================================================================
# Folder manipulation
#===============================================================================
def doclist_multifolder(folder_name):
    input_file_list = []
    for roots, dir, files in os.walk(folder_name):
        for file in files:
            file_uri = os.path.join(roots, file)
            file_uri = file_uri.replace("\\","/") #uncoment if running on windows           
            if file_uri.endswith('txt'): input_file_list.append(file_uri)
    return input_file_list
#creates list of documents in many folders

def fname_splitter(docslist):
    fnames = []
    for doc in docslist:
        blocks = doc.split('/')
        fnames.append(blocks[len(blocks)-1])
    return(fnames)
#getting the filenames from uri of whatever documents were processed in the input folder   