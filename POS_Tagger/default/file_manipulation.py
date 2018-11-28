'''
Created on Oct 26, 2018

@author: terry
'''
import os
import nltk
import re

from nltk.stem.lancaster import LancasterStemmer

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
            words = removeASCIItrash(words)
            words = makeLowerCase(words)
            words = words.split() #split by whitespace #comment if tokenize is performed
            #list operations
            words = cleanString(words)
            words = removeStopWords(words) #get rid of stop words
            words = applyStemmer(words) #LancasterStemming
            words = applyPOStag(words) #POS-tagger via NLTK
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
def applyStemmer(words):
    st = LancasterStemmer()
    ste_words = []
    for word in words:
        ste_words.append(st.stem(word))
    return (ste_words)
 #Applies Lancaster Stemmer to list of words   

def applyPOStag(words):
    tg = nltk.pos_tag(words)
    for t in tg:
        print(type(t))
    return (tg)
#apply POS tag via NLTK to list of words

def removeASCIItrash(words):
    cwords = words.encode('ascii', 'ignore').decode("utf-8")
    return (cwords)
#removing unwanted chars/trash from sentences as strings

def makeLowerCase(words):
    return(words.lower())
#everything in lower case from string

def removeStopWords(words):
    no_sw_words = [i for i in words[:] if not i in en_stop]
    return(no_sw_words)
#removes stopwords from list of words

def cleanString(words):
    tokens = []
    for word in words:
        clean_word = word.translate({ord(c): None for c in '()[]{}\'\".;:,!@#$'})
        if(clean_word): 
            tokens.append(clean_word) #only keep valid items
        else:
            pass # we don't want a empty space in the list
    return(tokens)
#returns a list of clean tokens - gets rid of anything between ' ' by  replacing for None
#it also removes the entry for that empty token in our list
