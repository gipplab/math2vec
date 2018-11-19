'''
Created on Oct 26, 2018

@author: terry
'''
import os
import nltk
import re

from stop_words import get_stop_words
en_stop = get_stop_words('en') # list of stopwords/english

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

#===============================================================================
# Document Reading/Writing
#===============================================================================
def cleanText(fname, input_file_abs, output_path):
    ops = open(output_path+'/'+fname,'w', encoding='utf-8') #file where we are writing (same name it was read)
    with open(input_file_abs, 'r', encoding='utf-8') as fin:
        for lines in fin.readlines():
            words = str(lines) #stream into string
            words = words.encode('ascii', 'ignore').decode("utf-8")
            #cleaning each line
            words = words.lower()#everything in lower case
            words = words.split() #split by whitespace #comment if tokenize is performed
            words = cleanString(words)
            words = [i for i in words[:] if not i in en_stop] #get rid of stop words
            #words = nltk.pos_tag(words) #POS-tagger via NLTK
            outputFile(words, ops)
        ops.close()
        fin.close()
#reads file line by line and clean it

def outputFile(text, writer):  
    if text:
        for words in text:
            writer.write(str(words) + ' ')
        writer.write('\n')
    else:
        #print('Empty line !!!')
        pass # nothing to save
#writes sentence into a file

#===============================================================================
# Filter and Manipulation of Strings
#===============================================================================
def cleanString(words):
    tokens = []
    for word in words:
        tokens.append(word.translate({ord(c): None for c in '()[]{}\'\".;:,!@#$'}))
    return(tokens)
#returns a list of clean tokens - gets rid of anything between ' ' by  replacing for None
#2018-11-14 at this point we are not sure what other chars we want to keep