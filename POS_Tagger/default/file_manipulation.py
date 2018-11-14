'''
Created on Oct 26, 2018

@author: terry
'''
import os
import nltk

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
    ops = open(output_path+'/'+fname,'w+') #file where we are writing (same name it was read)
    with open(input_file_abs, 'r', encoding='utf-8') as fin:
        for lines in fin.readlines():
            words = str(lines) #stream into string
            #cleaning each line
            words = words.lower() #everything in lower case
            #words = nltk.tokenize.word_tokenize(words)
            words = words.split() #split by whitespace #comment if tokenize is performed
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